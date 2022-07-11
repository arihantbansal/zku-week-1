pragma circom 2.0.3;

include "../node_modules/circomlib-matrix/circuits/matAdd.circom";
include "../node_modules/circomlib-matrix/circuits/matElemMul.circom";
include "../node_modules/circomlib-matrix/circuits/matElemSum.circom";
include "../node_modules/circomlib-matrix/circuits/matElemPow.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../../../contracts/circuits/RangeProof.circom";

template sudoku() {
    signal input puzzle[9][9]; // 0  where blank
    signal input solution[9][9]; // 0 where original puzzle is not blank
    signal output out;

    component mul = matElemMul(9,9);

    // Initialize RangeProof components 
    component puzzleRangeProof[9][9];
    component solutionRangeProof[9][9];

    for (var i=0; i<9; i++) {
        for (var j=0; j<9; j++) {
            puzzleRangeProof[i][j] = RangeProof(32);
            puzzleRangeProof[i][j].range[0] <== 0;
            puzzleRangeProof[i][j].range[1] <== 9;
            puzzleRangeProof[i][j].in <== puzzle[i][j];

            assert(puzzleRangeProof[i][j].out == 1);

            solutionRangeProof[i][j] = RangeProof(32);
            solutionRangeProof[i][j].range[0] <== 0;
            solutionRangeProof[i][j].range[1] <== 9;
            solutionRangeProof[i][j].in <== solution[i][j];
            
						assert(solutionRangeProof[i][j].out == 1);
            
						mul.a[i][j] <== puzzle[i][j];
            mul.b[i][j] <== solution[i][j];
        }
    }

    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            mul.out[i][j] === 0;
        }
    }

		// Sum up inputs
    component add = matAdd(9,9);
    
    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            add.a[i][j] <== puzzle[i][j];
            add.b[i][j] <== solution[i][j];
        }
    }

    component square = matElemPow(9,9,2);

    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            square.a[i][j] <== add.out[i][j];
        }
    }

    component row[9];
    component col[9];
    component block[9];
    component rowSquare[9];
    component colSquare[9];
    component blockSquare[9];

    for (var i = 0; i < 9; i++) {
        row[i] = matElemSum(1,9);
        col[i] = matElemSum(1,9);
        block[i] = matElemSum(3,3);

        rowSquare[i] = matElemSum(1,9);
        colSquare[i] = matElemSum(1,9);
        blockSquare[i] = matElemSum(3,3);

        for (var j = 0; j < 9; j++) {
            row[i].a[0][j] <== add.out[i][j];
            col[i].a[0][j] <== add.out[j][i];

            rowSquare[i].a[0][j] <== square.out[i][j];
            colSquare[i].a[0][j] <== square.out[j][i];
        }

        var x = 3 * (i % 3);
        var y = 3 * (i \ 3);

        for (var j = 0; j < 3; j++) {
            for (var k = 0; k < 3; k++) {
                block[i].a[j][k] <== add.out[x + j][y + k];
                blockSquare[i].a[j][k] <== square.out[x + j][y + k];
            }
        }

        row[i].out === 45;
        col[i].out === 45;
        block[i].out === 45;

        rowSquare[i].out === 285;
        colSquare[i].out === 285;
        blockSquare[i].out === 285;
    }

    component poseidon[9];
    component hash;

    hash = Poseidon(9);
    
    for (var j = 0; j < 9; j++) {
        poseidon[j] = Poseidon(9);
        for (var k = 0; k < 9; k++) {
            poseidon[j].inputs[k] <== puzzle[j][k];
        }
        hash.inputs[j] <== poseidon[j].out;
    }

    out <== hash.out;
}

component main = sudoku();