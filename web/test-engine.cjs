// Holds the browser stand-in's engine to the Swift engine's contract:
// every golden in its range, and every good golden still 85+ on the stepper.
const fs = require('fs');
const path = require('path');
const engine = require('./engine.js');
const root = path.join(__dirname, '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
const res = 'Sources/PantryScoring/Resources/sichuan/';
const content = engine.indexContent(read(res + 'cuisine.json'), read(res + 'ingredients.json').ingredients, read(res + 'dishes.json').dishes);
const goldens = read('Tests/PantryScoringTests/Fixtures/goldens.json').attempts;

let failures = 0;
const fail = (message) => { failures += 1; console.error('FAIL ' + message); };

for (const golden of goldens) {
  const result = engine.score(content, golden);
  if (result.total < golden.expect.min || result.total > golden.expect.max) {
    fail(`${golden.id} scored ${result.total}, wanted ${golden.expect.min}...${golden.expect.max}`);
  }
}

// In both measure systems (PD-041).
for (const system of ['metric', 'us']) {
  for (const golden of goldens.filter((g) => g.kind === 'good')) {
    const lines = golden.lines.map((line) => {
      const ingredient = content.ingredients[line.ingredientId];
      const ladder = engine.ladderFor(ingredient, system);
      const step = ladder.steps[engine.nearestIndex(ladder, ingredient, engine.grams(ingredient, line.amount, line.unit))];
      return { ingredientId: line.ingredientId, amount: step.amount, unit: step.unit };
    });
    const result = engine.score(content, { ...golden, lines });
    if (result.total < 85) fail(`${golden.id} on the ${system} stepper scored ${result.total}`);
  }
  for (const dishId of content.dishOrder) {
    const recipe = content.dishes[dishId].recipe;
    const lines = recipe.lines.map((line) => {
      const step = engine.recipeMeasure(content.ingredients[line.ingredientId], line, system);
      return { ingredientId: line.ingredientId, amount: step.amount, unit: step.unit };
    });
    const result = engine.score(content, { dishId, vessel: recipe.vessel, method: recipe.method, lines });
    if (result.total < 85 || result.misses.length) fail(`${dishId}'s recipe read in ${system} measures scored ${result.total}`);
  }
}
const tofuLine = { ingredientId: 'firm-tofu', amount: 400, unit: 'grams' }, stockLine = { ingredientId: 'stock', amount: 0.75, unit: 'cup' };
const labels = ['metric', 'us'].map((system) => [tofuLine, stockLine].map((line) => engine.recipeMeasure(content.ingredients[line.ingredientId], line, system).label).join(', '));
if (labels[0] !== '400 g, 180 ml' || labels[1] !== '14 oz, ¾ cup') fail('recipe measures drifted: ' + labels.join(' | '));

for (const id of Object.keys(content.ingredients)) {
  const ingredient = content.ingredients[id];
  const ladder = engine.ladderFor(ingredient, 'us');
  const start = ladder.steps[ladder.startIndex];
  const expected = ingredient.defaultUnit === 'grams' ? '4 oz' : '1 ' + ingredient.defaultUnit;
  if (start.label !== expected) fail(`${id} starts at ${start.label} in US measures, wanted ${expected}`);
  const metric = engine.ladderFor(ingredient, 'metric');
  if (ingredient.defaultUnit === 'grams' && metric.steps[metric.startIndex].label !== '100 g') fail(`${id} doesn't start at 100 g in metric`);
}

// Exact parity with the Swift engine: Tests/PantryGameTests/ParityTests.swift asserts the
// same file. Regenerate with `node web/test-engine.cjs --write-parity` after a deliberate
// scoring change, then make sure `swift test` agrees.
const parityPath = 'Tests/PantryScoringTests/Fixtures/parity.json';
function parityCases() {
  const scoring = goldens.map((golden) => {
    const r = engine.score(content, golden);
    return {
      id: golden.id, dishId: golden.dishId, vessel: golden.vessel, method: golden.method || null, lines: golden.lines,
      expect: { total: r.total, coverage: r.coverage, ratioFit: r.ratioFit, signature: r.signature, technique: r.technique,
        cappedAt: r.cappedAt, misses: r.misses.map((m) => m.kind + ':' + m.subject), line: engine.judgeKitchen(content, golden.dishId, r) },
    };
  });
  const extra = [
    ['mapo-tofu.pinch-of-basil', [['basil', 5, 'grams']]],
    ['mapo-tofu.cup-of-cream', [['cream', 240, 'grams']]],
    ['mapo-tofu.sesame-paste', [['sesame-paste', 1, 'tbsp']]],
  ];
  const goodMapo = goldens.find((g) => g.id === 'mapo-tofu.good');
  for (const [id, added] of extra) {
    const lines = goodMapo.lines.concat(added.map(([ingredientId, amount, unit]) => ({ ingredientId, amount, unit })));
    const r = engine.score(content, { ...goodMapo, lines });
    scoring.push({ id, dishId: goodMapo.dishId, vessel: goodMapo.vessel, method: goodMapo.method, lines,
      expect: { total: r.total, coverage: r.coverage, ratioFit: r.ratioFit, signature: r.signature, technique: r.technique,
        cappedAt: r.cappedAt, misses: r.misses.map((m) => m.kind + ':' + m.subject), line: engine.judgeKitchen(content, goodMapo.dishId, r) } });
  }
  const pantry = [];
  for (const dishId of content.dishOrder) {
    const palette = content.dishes[dishId].palette;
    const limit = engine.pantryLimit(content.dishes[dishId]);
    const sets = { first: palette.slice(0, limit), last: palette.slice(-limit).reverse(), every: palette.slice(), few: palette.filter((_, i) => i % 3 === 0) };
    for (const [name, picks] of Object.entries(sets)) {
      const verdict = engine.pantryJudge(content, dishId, picks);
      pantry.push({ id: dishId + '.' + name, dishId, picks, limit, expect: { ...verdict, line: engine.judgePantry(content, dishId, verdict) } });
    }
  }
  return { schemaVersion: 1, scoring, pantry };
}
if (process.argv.includes('--write-parity')) {
  fs.writeFileSync(path.join(root, parityPath), JSON.stringify(parityCases(), null, 1) + '\n');
  console.log('wrote ' + parityPath);
}
if (JSON.stringify(read(parityPath)) !== JSON.stringify(parityCases())) fail('web/engine.js no longer matches ' + parityPath);

// The first too-forgiving rounds (PB-023), pinned after the fix (PD-027).
const demo = engine.score(content, {
  dishId: 'mapo-tofu', vessel: 'wok', method: 'braise', lines: [
    ['firm-tofu', 400, 'grams'], ['neutral-oil', 2, 'tbsp'], ['doubanjiang', 2.5, 'tbsp'], ['garlic', 1, 'tbsp'],
    ['ginger', 2, 'tsp'], ['sichuan-peppercorn-ground', 2, 'tsp'], ['stock', 0.75, 'cup'], ['basil', 25, 'grams'],
    ['scallion', 3, 'tbsp'],
  ].map(([ingredientId, amount, unit]) => ({ ingredientId, amount, unit })),
});
if (demo.total >= 85) fail(`the basil mapo tofu scored ${demo.total}; anything that doesn't belong keeps a dish under 85`);
const drowned = engine.score(content, {
  dishId: 'mapo-tofu', vessel: 'wok', method: 'braise', lines: [
    ['firm-tofu', 100, 'grams'], ['doubanjiang', 1.5, 'tbsp'], ['garlic', 1, 'tbsp'], ['ginger', 1, 'tsp'], ['stock', 1, 'cup'],
    ['sichuan-peppercorn-ground', 1, 'tsp'], ['chili-flakes', 1, 'tsp'], ['scallion', 1, 'tbsp'],
  ].map(([ingredientId, amount, unit]) => ({ ingredientId, amount, unit })),
});
if (drowned.total > 75) fail(`every ratio too high scored ${drowned.total}`);

// The session summary, with the same numbers as SessionTests.swift.
const kitchenSession = engine.sessionSummary('kitchen', [90, 60, 100, 75, 40].map((points) => ({ points, outOf: 100 })));
if (kitchenSession.headlineNumber !== '73' || kitchenSession.line !== 'Solid cooking, with a dish or two to tighten.' ||
    kitchenSession.best !== 2 || kitchenSession.revisit !== 4) fail('kitchen session summary drifted: ' + JSON.stringify(kitchenSession));
const cleanPantry = engine.sessionSummary('pantry', [[6, 6], [7, 7], [5, 5], [8, 8], [5, 5]].map(([points, outOf]) => ({ points, outOf })));
if (cleanPantry.headlineNumber !== '31 of 31' || cleanPantry.line !== 'A strong service.' || cleanPantry.best !== 0 || cleanPantry.revisit !== -1) {
  fail('clean pantry session summary drifted: ' + JSON.stringify(cleanPantry));
}
const roughPantry = engine.sessionSummary('pantry', [[2, 6], [3, 7], [1, 5], [4, 8], [2, 5]].map(([points, outOf]) => ({ points, outOf })));
if (roughPantry.line !== 'A learning service. The cards are the shortcut.' || roughPantry.revisit !== 2) fail('rough pantry session summary drifted');

if (failures > 0) process.exit(1);
console.log(`ok: ${goldens.length} goldens in range, good goldens reachable on the stepper, parity file matches, basil mapo ${demo.total}, every-ratio-high ${drowned.total}`);
