const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { groth16, plonk } = require("snarkjs");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
	"21888242871839275222246405745257275088548364400416034343698204186575808495617"
);
const Fr = new F1Field(exports.p);

describe("HelloWorld", function () {
	this.timeout(100000000);
	let Verifier;
	let verifier;

	beforeEach(async function () {
		Verifier = await ethers.getContractFactory("HelloWorldVerifier");
		verifier = await Verifier.deploy();
		await verifier.deployed();
	});

	it("Circuit should multiply two numbers correctly", async function () {
		// import circuit
		const circuit = await wasm_tester("contracts/circuits/HelloWorld.circom");

		// define inputs for circuit
		const INPUT = {
			a: 2,
			b: 3,
		};

		// calculate witness using circuit and pre-defined inputs
		const witness = await circuit.calculateWitness(INPUT, true);

		//console.log(witness); // log the witness

		// assert claim that the output of the circuit is equivalent to a * b (the multiplication of the two inputs)
		assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
		assert(Fr.eq(Fr.e(witness[1]), Fr.e(6)));
	});

	it("Should return true for correct proof", async function () {
		// generate proof and circuit ouputs (public signals) using inputs (a & b), witness and keys
		const { proof, publicSignals } = await groth16.fullProve(
			{ a: "2", b: "3" },
			"contracts/circuits/HelloWorld/HelloWorld_js/HelloWorld.wasm",
			"contracts/circuits/HelloWorld/circuit_final.zkey"
		);

		// log first output public signal
		console.log("2x3 =", publicSignals[0]);

		// generates parameters for solidity verifier
		const calldata = await groth16.exportSolidityCallData(proof, publicSignals);

		// split calldata variable to array containing proof and inputs to be passed
		const argv = calldata
			.replace(/["[\]\s]/g, "")
			.split(",")
			.map((x) => BigInt(x).toString());

		// assign parameters to their respective variables
		const a = [argv[0], argv[1]];
		const b = [
			[argv[2], argv[3]],
			[argv[4], argv[5]],
		];
		const c = [argv[6], argv[7]];
		const Input = argv.slice(8);

		// call solidity verifier and veify the proof of a * b = c
		expect(await verifier.verifyProof(a, b, c, Input)).to.be.true;
	});

	it("Should return false for invalid proof", async function () {
		// feed inaccurate parameters to the solidity verifier
		let a = [0, 0];
		let b = [
			[0, 0],
			[0, 0],
		];
		let c = [0, 0];
		let d = [0];

		// verify that the verifier proves the fake params to be false
		expect(await verifier.verifyProof(a, b, c, d)).to.be.false;
	});
});

describe("Multiplier3 with Groth16", function () {
	let Verifier;
	let verifier;

	beforeEach(async function () {
		Verifier = await ethers.getContractFactory("Multiplier3Verifier");
		verifier = await Verifier.deploy();
		await verifier.deployed();
	});

	it("Circuit should multiply three numbers correctly", async function () {
		const circuit = await wasm_tester("contracts/circuits/Multiplier3.circom");

		const INPUT = {
			a: 2,
			b: 3,
			c: 4,
		};

		const witness = await circuit.calculateWitness(INPUT, true);

		console.log(witness);

		assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
		assert(Fr.eq(Fr.e(witness[1]), Fr.e(24)));
	});

	it("Should return true for correct proof", async function () {
		// procedure already explained in comments above for Multiplier2 / HelloWorld circuit
		const { proof, publicSignals } = await groth16.fullProve(
			{ a: "2", b: "3", c: "4" },
			"contracts/circuits/Multiplier3/Multiplier3_js/Multiplier3.wasm",
			"contracts/circuits/Multiplier3/circuit_final.zkey"
		);

		console.log("2 * 3 * 4 =", publicSignals[0]);

		const calldata = await groth16.exportSolidityCallData(proof, publicSignals);

		const argv = calldata
			.replace(/["[\]\s]/g, "")
			.split(",")
			.map((x) => BigInt(x).toString());

		const a = [argv[0], argv[1]];
		const b = [
			[argv[2], argv[3]],
			[argv[4], argv[5]],
		];
		const c = [argv[6], argv[7]];
		const Input = argv.slice(8);

		expect(await verifier.verifyProof(a, b, c, Input)).to.be.true;
	});

	it("Should return false for invalid proof", async function () {
		let a = [0, 0];
		let b = [
			[0, 0],
			[0, 0],
		];
		let c = [0, 0];
		let d = [0];

		expect(await verifier.verifyProof(a, b, c, d)).to.be.false;
	});
});

describe("Multiplier3 with PLONK", function () {
	let Verifier;
	let verifier;

	beforeEach(async function () {
		Verifier = await ethers.getContractFactory("PlonkVerifier");
		verifier = await Verifier.deploy();
		await verifier.deployed();
	});

	it("Should return true for correct proof", async function () {
		const { proof, publicSignals } = await plonk.fullProve(
			{ a: "2", b: "3", c: "4" },
			"contracts/circuits/Multiplier3_PLONK/Multiplier3_js/Multiplier3.wasm",
			"contracts/circuits/Multiplier3_PLONK/circuit_final.zkey"
		);

		console.log("2 * 3 * 4 =", publicSignals[0]);

		const calldata = await plonk.exportSolidityCallData(proof, publicSignals);
		const calldataProof = calldata.split(",")[0];

		expect(await verifier.verifyProof(calldataProof, publicSignals)).to.be.true;
	});

	it("Should return false for invalid proof", async function () {
		let a = [0, 0];
		let b = [0];

		expect(await verifier.verifyProof(a, b)).to.be.false;
	});
});

