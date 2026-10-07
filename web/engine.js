// Pantry browser stand-in: the scoring engine and round rules, ported from
// Sources/PantryScoring/Scorer.swift and Sources/PantryGame. The Swift code is the
// source of truth; web/test-engine.mjs holds this port to the same goldens.
(function (root) {
  'use strict';

  var TEASPOONS = { pinch: 1 / 8, tsp: 1, tbsp: 3, cup: 48 };
  var AXES = ['heat', 'numbing', 'acid', 'umami', 'sweet'];
  var W = {
    coverage: 40, ratioFit: 35, signature: 15, technique: 10, vessel: 6, method: 4,
    forbiddenFloor: 5, forbiddenScaled: 7, forbiddenFullAt: 0.10,
    ratioZeroAtFactor: 3, signatureZeroAtLevels: 2, maxLevel: 5
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

    var penalty = 0;
    order.forEach(function (id) {
      var family = content.ingredients[id].family;
      var isOff = cuisine.offCuisineFamilies.indexOf(family) >= 0;
      var isForbidden = dish.forbidden.indexOf(family) >= 0;
      if (!isOff && !isForbidden) return;
      var fraction = total > 0 ? byIngredient[id] / total : 0;
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

    var sum = coverage + ratioFit + signature + technique;
    return {
      coverage: tenths(coverage), ratioFit: tenths(ratioFit), signature: tenths(signature),
      technique: tenths(technique), total: Math.round(Math.min(100, Math.max(0, sum))),
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
    methodChoices: methodChoices, indexContent: indexContent, VOLUME: VOLUME, WEIGHT: WEIGHT
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.PantryEngine = api;
})(typeof window !== 'undefined' ? window : globalThis);
