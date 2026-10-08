// Pantry browser stand-in: the scoring engine and round rules, ported from
// Sources/PantryScoring/Scorer.swift and Sources/PantryGame. The Swift code is the
// source of truth; web/test-engine.mjs holds this port to the same goldens.
(function (root) {
  'use strict';

  var TEASPOONS = { pinch: 1 / 8, tsp: 1, tbsp: 3, cup: 48 };
  var AXES = ['heat', 'numbing', 'acid', 'umami', 'sweet'];
  var W = {
    coverage: 30, ratioFit: 45, signature: 15, technique: 10, vessel: 6, method: 4,
    forbiddenFloor: 5, forbiddenScaled: 7, forbiddenFullAt: 0.10,
    ratioZeroAtFactor: 2.5, signatureZeroAtLevels: 2, maxLevel: 5,
    wrongIngredientCeiling: 79, wrongIngredientLowCeiling: 50, wrongIngredientLowAt: 0.10
  };

  function grams(ingredient, amount, unit) {
    if (unit === 'grams') return amount;
    var per = ingredient.gramsPerTeaspoon;
    if (per === undefined || per === null) return null;
    return amount * TEASPOONS[unit] * per;
  }

  function bandCredit(ratio, low, high) {
    if (ratio >= low && ratio <= high) return 1;
    if (!(ratio > 0)) return 0;
    var edge = ratio < low ? low : high;
    return Math.max(0, 1 - Math.abs(Math.log(ratio / edge)) / Math.log(W.ratioZeroAtFactor));
  }

  function tenths(value) { return Math.round(value * 10) / 10; }

  // content: { cuisine, ingredients: {id: ingredient}, dishes: {id: dish} }
  function score(content, attempt) {
    var dish = content.dishes[attempt.dishId];
    var cuisine = content.cuisine;
    var misses = [];
    var byFamily = {}, byIngredient = {}, order = [], total = 0;

    attempt.lines.forEach(function (line) {
      var ingredient = content.ingredients[line.ingredientId];
      if (!ingredient) { misses.push({ kind: 'unknownIngredient', subject: line.ingredientId }); return; }
      if (!(line.amount > 0)) return;
      var g = grams(ingredient, line.amount, line.unit);
      if (g === null) { misses.push({ kind: 'unmeasurable', subject: line.ingredientId + ' in ' + line.unit }); return; }
      byFamily[ingredient.family] = (byFamily[ingredient.family] || 0) + g;
      if (byIngredient[ingredient.id] === undefined) order.push(ingredient.id);
      byIngredient[ingredient.id] = (byIngredient[ingredient.id] || 0) + g;
      total += g;
    });
    function familyGrams(families) {
      return families.reduce(function (sum, f) { return sum + (byFamily[f] || 0); }, 0);
    }
    function weightOf(x) { return x.weight === undefined ? 1 : x.weight; }

    var grosslyOff = {};
    dish.ratios.forEach(function (band) {
      var n = familyGrams(band.numerator), d = familyGrams(band.denominator);
      if (n > 0 && d > 0 && bandCredit(n / d, band.low, band.high) === 0) {
        band.numerator.forEach(function (f) { grosslyOff[f] = true; });
      }
    });

    var requiredWeight = dish.required.reduce(function (s, r) { return s + weightOf(r); }, 0);
    var earned = 0;
    dish.required.forEach(function (req) {
      var need = Math.max(1, req.minPresent === undefined ? 1 : req.minPresent);
      var present = req.anyOf.filter(function (f) { return (byFamily[f] || 0) > 0; }).length;
      var w = weightOf(req);
      if (present >= need) {
        if (req.anyOf.some(function (f) { return grosslyOff[f]; })) {
          earned += w / 2; misses.push({ kind: 'wrongAmount', subject: req.label });
        } else { earned += w; }
      } else if (present === 0) {
        misses.push({ kind: 'missingRequired', subject: req.label });
      } else {
        earned += w * present / need; misses.push({ kind: 'partialRequired', subject: req.label });
      }
    });
    var coverage = requiredWeight > 0 ? W.coverage * earned / requiredWeight : W.coverage;

    var penalty = 0, wrongFraction = 0, hasWrong = false;
    order.forEach(function (id) {
      var family = content.ingredients[id].family;
      var isOff = cuisine.offCuisineFamilies.indexOf(family) >= 0;
      var isForbidden = dish.forbidden.indexOf(family) >= 0;
      if (!isOff && !isForbidden) return;
      var fraction = total > 0 ? byIngredient[id] / total : 0;
      hasWrong = true;
      wrongFraction += fraction;
      penalty += W.forbiddenFloor + W.forbiddenScaled * Math.min(1, fraction / W.forbiddenFullAt);
      misses.push({ kind: isOff ? 'offCuisine' : 'forbiddenForDish', subject: id });
    });
    coverage = Math.max(0, coverage - penalty);

    var ratioWeight = dish.ratios.reduce(function (s, b) { return s + weightOf(b); }, 0);
    var ratioCredit = 0;
    dish.ratios.forEach(function (band) {
      var n = familyGrams(band.numerator), d = familyGrams(band.denominator);
      if (!(n > 0 && d > 0)) { misses.push({ kind: 'ratioUndefined', subject: band.label }); return; }
      var ratio = n / d;
      ratioCredit += weightOf(band) * bandCredit(ratio, band.low, band.high);
      if (ratio < band.low) misses.push({ kind: 'ratioLow', subject: band.label });
      else if (ratio > band.high) misses.push({ kind: 'ratioHigh', subject: band.label });
    });
    var ratioFit = ratioWeight > 0 ? W.ratioFit * ratioCredit / ratioWeight : W.ratioFit;

    var envelope = dish.signature || cuisine.signature;
    var levels = {}, signatureCredit = 0;
    AXES.forEach(function (axis) {
      var level = 0;
      if (total > 0) {
        order.forEach(function (id) {
          level += ((content.ingredients[id].potency || {})[axis] || 0) * (byIngredient[id] / total * 100);
        });
      }
      level = Math.min(W.maxLevel, level);
      levels[axis] = level;
      var low = envelope[axis][0], high = envelope[axis][1];
      if (level >= low && level <= high) { signatureCredit += 1; return; }
      var distance = level < low ? low - level : level - high;
      signatureCredit += Math.max(0, 1 - distance / W.signatureZeroAtLevels);
      misses.push({ kind: level < low ? 'signatureLow' : 'signatureHigh', subject: axis });
    });
    var signature = W.signature * signatureCredit / AXES.length;

    var vesselFits = dish.vessels.indexOf(attempt.vessel) >= 0;
    var technique = 0;
    if (attempt.method) {
      technique += vesselFits ? W.vessel : 0;
      if (dish.methods.indexOf(attempt.method) >= 0) technique += W.method;
      else misses.push({ kind: 'wrongMethod', subject: attempt.method });
    } else {
      technique = vesselFits ? W.technique : 0;
    }
    if (!vesselFits) misses.push({ kind: 'wrongVessel', subject: attempt.vessel });

    var sum = Math.round(Math.min(100, Math.max(0, coverage + ratioFit + signature + technique)));
    // PD-027: anything that doesn't belong sets a ceiling, lower the more of the dish it is.
    var cappedAt = null;
    if (hasWrong) {
      var slide = Math.min(1, wrongFraction / W.wrongIngredientLowAt);
      var limit = W.wrongIngredientCeiling - (W.wrongIngredientCeiling - W.wrongIngredientLowCeiling) * slide;
      if (sum > limit) cappedAt = Math.floor(limit);
    }
    return {
      coverage: tenths(coverage), ratioFit: tenths(ratioFit), signature: tenths(signature),
      technique: tenths(technique), total: cappedAt === null ? sum : cappedAt, cappedAt: cappedAt,
      levels: levels, misses: misses
    };
  }

  // The amount stepper (Sources/PantryGame/AmountLadder.swift).
  var VOLUME = [
    [1, 'pinch', 'pinch'], [0.25, 'tsp', '¼ tsp'], [0.5, 'tsp', '½ tsp'], [1, 'tsp', '1 tsp'],
    [1.5, 'tsp', '1½ tsp'], [2, 'tsp', '2 tsp'], [1, 'tbsp', '1 tbsp'], [1.5, 'tbsp', '1½ tbsp'],
    [2, 'tbsp', '2 tbsp'], [2.5, 'tbsp', '2½ tbsp'], [3, 'tbsp', '3 tbsp'], [0.25, 'cup', '¼ cup'],
    [1 / 3, 'cup', '⅓ cup'], [0.5, 'cup', '½ cup'], [0.75, 'cup', '¾ cup'], [1, 'cup', '1 cup'],
    [1.5, 'cup', '1½ cups'], [2, 'cup', '2 cups'], [2.5, 'cup', '2½ cups'], [3, 'cup', '3 cups'],
    [4, 'cup', '4 cups']
  ].map(function (s) { return { amount: s[0], unit: s[1], label: s[2] }; });
  var WEIGHT = [5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 200, 250, 300, 350, 400, 500, 600, 750, 1000]
    .map(function (g) { return { amount: g, unit: 'grams', label: g === 1000 ? '1 kg' : g + ' g' }; });

  function ladderFor(ingredient) {
    var byWeight = ingredient.defaultUnit === 'grams' || ingredient.gramsPerTeaspoon === undefined || ingredient.gramsPerTeaspoon === null;
    var steps = byWeight ? WEIGHT : VOLUME;
    var start = 0;
    for (var i = 0; i < steps.length; i++) {
      if (byWeight ? steps[i].amount === 100 : (steps[i].unit === ingredient.defaultUnit && steps[i].amount === 1)) { start = i; break; }
    }
    return { steps: steps, startIndex: start };
  }

  function nearestIndex(ladder, ingredient, targetGrams) {
    var best = 0, bestDistance = Infinity;
    ladder.steps.forEach(function (step, index) {
      var g = grams(ingredient, step.amount, step.unit);
      if (!(g > 0)) return;
      var distance = Math.abs(Math.log(g / targetGrams));
      if (distance < bestDistance) { best = index; bestDistance = distance; }
    });
    return best;
  }

  function pieceCount(ladder, index, most) {
    most = most || 4;
    return 1 + Math.floor(index * (most - 1) / (ladder.steps.length - 1));
  }

  // Pantry mode (Sources/PantryGame/PantryRound.swift).
  var PANTRY_SLACK = 0;
  function need(requirement) { return Math.max(1, requirement.minPresent === undefined ? 1 : requirement.minPresent); }
  function pantryEssentials(dish) {
    return dish.required.reduce(function (sum, r) { return sum + need(r); }, 0);
  }
  function pantryLimit(dish) {
    var unique = dish.palette.filter(function (id, i) { return dish.palette.indexOf(id) === i; }).length;
    return Math.min(unique, pantryEssentials(dish) + PANTRY_SLACK);
  }
  function pantryJudge(content, dishId, picks) {
    var dish = content.dishes[dishId];
    var filled = dish.required.map(function () { return []; });
    var result = { found: [], missed: [], alsoBelongs: [], wrong: [], essentials: pantryEssentials(dish) };
    var seen = {};
    picks.forEach(function (id) {
      var ingredient = content.ingredients[id];
      if (seen[id] || !ingredient) return;
      seen[id] = true;
      var family = ingredient.family;
      if (content.cuisine.offCuisineFamilies.indexOf(family) >= 0 || dish.forbidden.indexOf(family) >= 0) { result.wrong.push(id); return; }
      var filledASlot = false;
      for (var i = 0; i < dish.required.length && !filledASlot; i++) {
        var r = dish.required[i];
        if (r.anyOf.indexOf(family) >= 0 && filled[i].length < need(r) && filled[i].indexOf(family) < 0) {
          filled[i].push(family); filledASlot = true;
        }
      }
      (filledASlot ? result.found : result.alsoBelongs).push(id);
    });
    dish.required.forEach(function (r, i) { if (filled[i].length < need(r)) result.missed.push(r.label); });
    return result;
  }

  // The judge's one line: Sources/PantryGame/JudgeLine.swift, sentence for sentence.
  var JUDGE_PRIORITY = ['offCuisine', 'forbiddenForDish', 'missingRequired', 'wrongVessel', 'wrongMethod',
    'partialRequired', 'wrongAmount', 'ratioHigh', 'ratioLow', 'signatureHigh', 'signatureLow'];
  var GERUND = { 'stir-fry': 'stir-frying', 'deep-fry': 'deep-frying', 'dry-fry': 'dry-frying', braise: 'braising', boil: 'boiling',
    simmer: 'simmering', steam: 'steaming', poach: 'poaching', bake: 'baking' };
  var VESSEL_NOUN = { wok: 'wok', pot: 'pot', pan: 'pan', skillet: 'skillet', 'baking-dish': 'baking dish', 'bread-pan': 'bread pan' };
  var AXIS_NAME = { heat: 'heat', numbing: 'numbing', acid: 'sourness', umami: 'savoury depth', sweet: 'sweetness' };
  var PROPER = ['Sichuan', 'Shaoxing', 'Chinkiang', 'Napa', 'Chongqing'];
  function lowerFirst(name) {
    for (var i = 0; i < PROPER.length; i++) if (name.indexOf(PROPER[i]) === 0) return name;
    return name.charAt(0).toLowerCase() + name.slice(1);
  }
  function judgeName(content, id) { var i = content.ingredients[id]; return lowerFirst(i ? (i.shortName || i.name) : id); }
  function ratioSides(label) {
    var sides = label.split(' (')[0].split(' to ');
    return sides.length === 2 ? sides : null;
  }
  function judgeKitchen(content, dishId, result) {
    var dish = content.dishes[dishId], name = lowerFirst(dish.name), miss = null, i, j;
    for (i = 0; i < JUDGE_PRIORITY.length && !miss; i++) {
      for (j = 0; j < result.misses.length; j++) if (result.misses[j].kind === JUDGE_PRIORITY[i]) { miss = result.misses[j]; break; }
    }
    if (!miss) return result.total >= 95 ? "That's " + name + '. Nothing to fix.' : 'Close to the mark all round.';
    var earned = result.coverage + result.ratioFit + result.signature + result.technique;
    var leaveOut = earned >= 80 ? 'Leave that out and this is close.' : 'Start by leaving that out.';
    var s = miss.subject, sides;
    switch (miss.kind) {
      case 'offCuisine': return 'The ' + judgeName(content, s) + ' came from another kitchen. ' + leaveOut;
      case 'forbiddenForDish': return 'No ' + judgeName(content, s) + ' in ' + name + '. ' + leaveOut;
      case 'missingRequired': return "It isn't " + name + ' without ' + s + '.';
      case 'wrongVessel':
        var pan = dish.recipe ? dish.recipe.vessel : dish.vessels[0];
        return pan ? 'Right idea, wrong pan: ' + name + ' is cooked in a ' + VESSEL_NOUN[pan] + '.' : 'Right idea, wrong pan.';
      case 'wrongMethod':
        var used = GERUND[s] || s, start = used.charAt(0).toUpperCase() + used.slice(1);
        var wanted = dish.recipe ? dish.recipe.method : dish.methods[0];
        return wanted ? start + ' is the wrong method here: ' + name + ' wants ' + GERUND[wanted] + '.' : start + ' is the wrong method here.';
      case 'partialRequired': return "It's thin on " + s + '.';
      case 'wrongAmount': return "There's " + s + ' in it, but the amount is far off.';
      case 'ratioHigh': sides = ratioSides(s); return sides ? 'Too much ' + sides[0] + ' for the ' + sides[1] + '.' : 'Too much ' + s + '.';
      case 'ratioLow': sides = ratioSides(s); return sides ? 'It wants more ' + sides[0] + ' for that much ' + sides[1] + '.' : 'It wants more ' + s + '.';
      case 'signatureHigh': return 'Too much ' + (AXIS_NAME[s] || s) + ' for ' + name + '.';
      case 'signatureLow': return 'It wants more ' + (AXIS_NAME[s] || s) + '.';
    }
    return 'Close to the mark all round.';
  }
  function judgePantry(content, dishId, result) {
    var dish = content.dishes[dishId];
    if (result.found.length === result.essentials && !result.wrong.length) return 'All ' + result.essentials + " essentials, and nothing that doesn't belong.";
    if (result.wrong.length) {
      var line = 'No ' + judgeName(content, result.wrong[0]) + ' in ' + lowerFirst(dish.name) + '.';
      return result.missed.length ? line + ' And it still needs ' + result.missed[0] + '.' : line;
    }
    if (!result.missed.length) return result.found.length + ' of ' + result.essentials + ' essentials found.';
    if (result.essentials - result.found.length === 1) return 'One short: it needs ' + result.missed[0] + '.';
    return result.found.length + ' of ' + result.essentials + '. Start with ' + result.missed[0] + '.';
  }

  // What the summary says about a finished session: Sources/PantryGame/Session.swift, SessionSummary.
  function sessionSummary(mode, records) {
    var points = 0, outOf = 0, sum = 0, best = -1, revisit = -1, i;
    function fraction(r) { return r.outOf > 0 ? r.points / r.outOf : 0; }
    for (i = 0; i < records.length; i++) {
      points += records[i].points; outOf += records[i].outOf; sum += fraction(records[i]);
      if (best < 0 || fraction(records[i]) > fraction(records[best])) best = i;
      if (revisit < 0 || fraction(records[i]) < fraction(records[revisit])) revisit = i;
    }
    var average = records.length ? sum / records.length : 0;
    if (records.length < 2 || revisit === best || fraction(records[revisit]) >= 1) revisit = -1;
    return {
      headlineNumber: mode === 'kitchen' ? String(records.length ? Math.round(points / records.length) : 0) : points + ' of ' + outOf,
      headlineCaption: (mode === 'kitchen' ? 'average across ' : 'essentials found across ') + records.length + ' dishes',
      line: average >= 0.85 ? 'A strong service.' : average >= 0.65 ? 'Solid cooking, with a dish or two to tighten.' : 'A learning service. The cards are the shortcut.',
      best: best, revisit: revisit
    };
  }

  var METHOD_ORDER = ['stir-fry', 'deep-fry', 'dry-fry', 'braise', 'boil', 'simmer', 'steam', 'poach', 'bake'];
  function methodChoices(content) {
    var used = {};
    Object.keys(content.dishes).forEach(function (id) { content.dishes[id].methods.forEach(function (m) { used[m] = true; }); });
    return METHOD_ORDER.filter(function (m) { return used[m]; });
  }

  function indexContent(cuisine, ingredientList, dishList) {
    var ingredients = {}, dishes = {};
    ingredientList.forEach(function (i) { ingredients[i.id] = i; });
    dishList.forEach(function (d) { dishes[d.id] = d; });
    return { cuisine: cuisine, ingredients: ingredients, dishes: dishes, dishOrder: dishList.map(function (d) { return d.id; }) };
  }

  var api = {
    score: score, grams: grams, ladderFor: ladderFor, nearestIndex: nearestIndex, pieceCount: pieceCount,
    methodChoices: methodChoices, indexContent: indexContent, VOLUME: VOLUME, WEIGHT: WEIGHT, WEIGHTS: W,
    pantryJudge: pantryJudge, pantryEssentials: pantryEssentials, pantryLimit: pantryLimit,
    judgeKitchen: judgeKitchen, judgePantry: judgePantry, sessionSummary: sessionSummary
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.PantryEngine = api;
})(typeof window !== 'undefined' ? window : globalThis);
