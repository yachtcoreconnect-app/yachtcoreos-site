import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const sales = await readFile(resolve(root, "calculator-pack.html"), "utf8");
const success = await readFile(resolve(root, "calculator-pack-success.html"), "utf8");
const about = await readFile(resolve(root, "about.html"), "utf8");

assert.match(sales, /Yacht Crew Work &amp; Cost Calculator Pack/i);
assert.match(sales, /\$12/);
assert.match(sales, /Stripe Sandbox/i);
assert.match(sales, /https:\/\/buy\.stripe\.com\/test_fZudR8fS865ib2gfHUao800/);
assert.match(sales, /Yacht Work Rate Calculator/);
assert.match(sales, /Dockage Cost Estimator/);
assert.match(sales, /Crew Rotation Planner/);
assert.match(sales, /manual/i);
assert.match(sales, /\/about\.html/);

assert.match(success, /No real payment was collected/i);
assert.match(success, /redirect alone (?:does not|never) prove(?:s)? payment/i);
assert.match(success, /\/calculator-pack\.html/);

assert.match(about, /SOF YACHT FLOW LLC/);
assert.doesNotMatch(sales + success + about, /\b(?:sk|rk)_(?:test|live)_/);

const packagePath = resolve(root, "..", "downloads", "YachtCrewCalculatorPack-v1.0.zip");
const packageBytes = await readFile(packagePath);
const checksum = createHash("sha256").update(packageBytes).digest("hex");
assert.equal(checksum, "2c7ecdb7716faee2c9c207bb4cfb5c0492d530ff228e831ed59cea5bf921eb99");

console.log("Calculator Pack static checks passed.");
