pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib-matrix/circuits/matMul.circom";
include "../../node_modules/circomlib-matrix/circuits/matSub.circom";

template SystemOfEquations(n) { // n is the number of variables in the system of equations
    signal input x[n]; // this is the solution to the system of equations
    signal input A[n][n]; // this is the coefficient matrix
    signal input b[n]; // this are the constants in the system of equations
    signal output out; // 1 for correct solution, 0 for incorrect solution

		component mat_mul = matMul(n, n, 1);

		// Initialize matrices A & x
    for (var i = 0; i < n; i++) {
        mat_mul.b[i][0] <== x[i];

        for (var j = 0; j < n; j++) {
            mat_mul.a[i][j] <== A[i][j];
        }
    }

    component mat_sub = matSub(n, 1);

		// Subtract 
    for (var i = 0; i < n; i++) {
        mat_sub.a[i][0] <== mat_mul.out[i][0];
        mat_sub.b[i][0] <== b[i];
    }

    var sum = 0;
    for (var i = 0; i < n; i++) {
				// Add up values of mat_sub.out, should equal to 0 is the system of equations is solved
        sum += mat_sub.out[i][0];
    }

		// Check if value of sum == 0
    component isEqual = IsEqual(); 
    isEqual.in[0] <== sum;
    isEqual.in[1] <== 0;

    out <== isEqual.out;
}

component main { public [A, b] } = SystemOfEquations(3);