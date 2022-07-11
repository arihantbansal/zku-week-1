pragma circom 2.0.0;

template Multiplier3 () {  

   // Declaration of signals.  
   signal input a;  
   signal input b;
   signal input c;
	 signal intermediateMultiplier; // holds the intermediate multiplication value
   signal output d;  

	intermediateMultiplier <== a * b; // computing intermediate value

   // Constraints.
   d <== intermediateMultiplier * c; // computing final value
}

component main = Multiplier3();