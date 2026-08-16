import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const sales = await readFile(resolve(root, "calculator-pack.html"), "utf8");
const success = await readFile(resolve(root, "calculator-pack-success.html"), "utf8");
const about = await readFile(resolve(root, "about.html"), "utf8");
const policies = await readFile(resolve(root, "calculator-pack-policies.html"), "utf8");

assert.match(sales, /Yacht Crew Work &amp; Cost Calculator Pack/i);
assert.match(sales, /\$12/);
assert.match(sales, /Stripe Sandbox/i);
assert.match(sales, /https:\/\/buy\.stripe\.com\/test_fZudR8fS865ib2gfHUao800/);
assert.match(sales, /Yacht Work Rate Calculator/);
assert.match(sales, /Dockage Cost Estimator/);
assert.match(sales, /Crew Rotation Planner/);
assert.match(sales, /manual/i);
assert.match(sales, /\/about\.html/);
assert.match(sales, /AI-assisted planning tools/i);
assert.match(sales, /appropriately qualified person remains responsible/i);
assert.match(sales, /adults 18\+/i);
assert.match(sales, /\/calculator-pack-policies\.html/);

assert.match(policies, /not directed to children under 13/i);
assert.match(policies, /email address/i);
assert.match(policies, /do not ask for or store card numbers/i);
assert.match(policies, /do not sell personal information/i);
assert.match(policies, /14-day refund/i);
assert.match(policies, /appropriately qualified person remain responsible/i);

assert.match(success, /No real payment was collected/i);
assert.match(success, /redirect alone (?:does not|never) prove(?:s)? payment/i);
assert.match(success, /\/calculator-pack\.html/);

assert.match(about, /SOF YACHT FLOW LLC/);
assert.doesNotMatch(sales + success + about + policies, /\b(?:sk|rk)_(?:test|live)_/);

const packagePath = resolve(root, "..", "downloads", "YachtCrewCalculatorPack-v1.0.1.zip");
const packageBytes = await readFile(packagePath);
const checksum = createHash("sha256").update(packageBytes).digest("hex");
assert.equal(checksum, "476b1d8a8965f7c950e03bcabe5de068526ba4b2ae86c2c78c5d7795fecbdcc5");

console.log("Calculator Pack static checks passed.");
