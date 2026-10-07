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

for (const golden of goldens.filter((g) => g.kind === 'good')) {
  const lines = golden.lines.map((line) => {
    const ingredient = content.ingredients[line.ingredientId];
    const ladder = engine.ladderFor(ingredient);
    const step = ladder.steps[engine.nearestIndex(ladder, ingredient, engine.grams(ingredient, line.amount, line.unit))];
    return { ingredientId: line.ingredientId, amount: step.amount, unit: step.unit };
  });
  const result = engine.score(content, { ...golden, lines });
  if (result.total < 85) fail(`${golden.id} on the stepper scored ${result.total}`);
}

for (const id of Object.keys(content.ingredients)) {
  const ingredient = content.ingredients[id];
  const ladder = engine.ladderFor(ingredient);
  const start = ladder.steps[ladder.startIndex];
  const expected = ingredient.defaultUnit === 'grams' ? '100 g' : '1 ' + ingredient.defaultUnit;
  if (start.label !== expected) fail(`${id} starts at ${start.label}, wanted ${expected}`);
}

// The CI demo round in the app scores 88 (see PB-023); the port must agree.
const demo = engine.score(content, {
  dishId: 'mapo-tofu', vessel: 'wok', method: 'braise', lines: [
    ['firm-tofu', 400, 'grams'], ['neutral-oil', 2, 'tbsp'], ['doubanjiang', 2.5, 'tbsp'], ['garlic', 1, 'tbsp'],
    ['ginger', 2, 'tsp'], ['sichuan-peppercorn-ground', 2, 'tsp'], ['stock', 0.75, 'cup'], ['basil', 25, 'grams'],
    ['scallion', 3, 'tbsp'],
  ].map(([ingredientId, amount, unit]) => ({ ingredientId, amount, unit })),
});
if (demo.total !== 88) fail(`demo round scored ${demo.total}, the app scores 88`);

if (failures > 0) process.exit(1);
console.log(`ok: ${goldens.length} goldens in range, good goldens reachable on the stepper, demo round ${demo.total}`);
