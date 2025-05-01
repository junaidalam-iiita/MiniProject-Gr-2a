pragma circom 2.0.0;

include "circomlib/circuits/comparators.circom";

template XOR8() {
    signal input a[8];
    signal input b[8];
    signal output out[8];
    for (var i = 0; i < 8; i++) {
        out[i] <== a[i] + b[i] - 2*a[i]*b[i];
    }
}

template CountSetBits() {
    signal input x[8];
    signal output count;
    signal intermediate[9];
    intermediate[0] <== 0;
    for (var i = 0; i < 8; i++) {
        intermediate[i+1] <== intermediate[i] + x[i];
    }
    count <== intermediate[8];
}

template HammingDistance(n) {
    signal input desc1[n][8];
    signal input desc2[n][8];
    signal output total_distance;
    
    component xor[n];
    component count[n];
    signal intermediate[n+1];
    intermediate[0] <== 0;
    
    for (var i = 0; i < n; i++) {
        xor[i] = XOR8();
        xor[i].a <== desc1[i];
        xor[i].b <== desc2[i];
        
        count[i] = CountSetBits();
        count[i].x <== xor[i].out;
        
        intermediate[i+1] <== intermediate[i] + count[i].count;
    }
    total_distance <== intermediate[n];
}

template Sort4BySecond() {
    signal input tuples[4][2];
    signal output sorted[4][2];
    
    component lt[5];
    for (var i = 0; i < 5; i++) {
        lt[i] = LessThan(32);
    }
    
    // Stage 1: Compare elements 0-1 and 2-3
    lt[0].in[0] <== tuples[1][1]; lt[0].in[1] <== tuples[0][1];
    lt[1].in[0] <== tuples[3][1]; lt[1].in[1] <== tuples[2][1];
    
    signal s1[4][2];
    s1[0][0] <== tuples[0][0] + lt[0].out*(tuples[1][0]-tuples[0][0]);
    s1[0][1] <== tuples[0][1] + lt[0].out*(tuples[1][1]-tuples[0][1]);
    s1[1][0] <== tuples[1][0] + lt[0].out*(tuples[0][0]-tuples[1][0]);
    s1[1][1] <== tuples[1][1] + lt[0].out*(tuples[0][1]-tuples[1][1]);
    s1[2][0] <== tuples[2][0] + lt[1].out*(tuples[3][0]-tuples[2][0]);
    s1[2][1] <== tuples[2][1] + lt[1].out*(tuples[3][1]-tuples[2][1]);
    s1[3][0] <== tuples[3][0] + lt[1].out*(tuples[2][0]-tuples[3][0]);
    s1[3][1] <== tuples[3][1] + lt[1].out*(tuples[2][1]-tuples[3][1]);
    
    // Stage 2: Cross comparisons
    lt[2].in[0] <== s1[2][1]; lt[2].in[1] <== s1[0][1];
    lt[3].in[0] <== s1[3][1]; lt[3].in[1] <== s1[1][1];
    
    signal s2[4][2];
    s2[0][0] <== s1[0][0] + lt[2].out*(s1[2][0]-s1[0][0]);
    s2[0][1] <== s1[0][1] + lt[2].out*(s1[2][1]-s1[0][1]);
    s2[2][0] <== s1[2][0] + lt[2].out*(s1[0][0]-s1[2][0]);
    s2[2][1] <== s1[2][1] + lt[2].out*(s1[0][1]-s1[2][1]);
    s2[1][0] <== s1[1][0] + lt[3].out*(s1[3][0]-s1[1][0]);
    s2[1][1] <== s1[1][1] + lt[3].out*(s1[3][1]-s1[1][1]);
    s2[3][0] <== s1[3][0] + lt[3].out*(s1[1][0]-s1[3][0]);
    s2[3][1] <== s1[3][1] + lt[3].out*(s1[1][1]-s1[3][1]);
    
    // Stage 3: Final comparison
    lt[4].in[0] <== s2[2][1]; lt[4].in[1] <== s2[1][1];
    
    sorted[0][0] <== s2[0][0]; sorted[0][1] <== s2[0][1];
    sorted[1][0] <== s2[1][0] + lt[4].out*(s2[2][0]-s2[1][0]);
    sorted[1][1] <== s2[1][1] + lt[4].out*(s2[2][1]-s2[1][1]);
    sorted[2][0] <== s2[2][0] + lt[4].out*(s2[1][0]-s2[2][0]);
    sorted[2][1] <== s2[2][1] + lt[4].out*(s2[1][1]-s2[2][1]);
    sorted[3][0] <== s2[3][0]; sorted[3][1] <== s2[3][1];
}

template RatioTestSingle() {
    signal input distance1;
    signal input distance2;
    signal lowes_ratio <== 7000; // 0.7 * 10000
    
    signal lhs <== distance1 * 10000;
    signal rhs <== distance2 * lowes_ratio;
    
    component lt = LessThan(64);
    lt.in[0] <== lhs;
    lt.in[1] <== rhs;
    
    signal output is_valid <==  lt.out;
}

template FingerprintVerifier() {
    signal input query_descriptors[2][32][8];
    signal input train_descriptors[4][32][8];
    
    signal lowes_ratio <== 7000;
    signal min_matches <== 1;
    
    component hd[2][4];
    signal distances[2][4][2];
    
    for (var q = 0; q < 2; q++) {
        for (var t = 0; t < 4; t++) {
            hd[q][t] = HammingDistance(32);
            hd[q][t].desc1 <== query_descriptors[q];
            hd[q][t].desc2 <== train_descriptors[t];
            
            distances[q][t][0] <== t;
            distances[q][t][1] <== hd[q][t].total_distance;
        }
    }
    
    component sorters[2];
    signal top_matches[2][2][2]; // [query][rank][index/distance]
    
    for (var q = 0; q < 2; q++) {
        sorters[q] = Sort4BySecond();
        for (var t = 0; t < 4; t++) {
            sorters[q].tuples[t] <== distances[q][t];
        }
        
        // Store both top matches
        top_matches[q][0][0] <== sorters[q].sorted[0][0]; // Best index
        top_matches[q][0][1] <== sorters[q].sorted[0][1]; // Best distance
        top_matches[q][1][0] <== sorters[q].sorted[1][0]; // Second-best index
        top_matches[q][1][1] <== sorters[q].sorted[1][1]; // Second-best distance
    }
    
    component ratioTests[2];
    signal valid_matches[2];
    
    for (var q = 0; q < 2; q++) {
        ratioTests[q] = RatioTestSingle();
        ratioTests[q].distance1 <== top_matches[q][0][1];
        ratioTests[q].distance2 <== top_matches[q][1][1];
        valid_matches[q] <== ratioTests[q].is_valid;
    }
    
    signal match_sum <== valid_matches[0] + valid_matches[1];
    
    component lt_min = LessThan(32);
    lt_min.in[0] <== match_sum ;
    lt_min.in[1] <== min_matches;
    signal output is_match <== 1 - lt_min.out;
    
    // Enhanced debug outputs
    signal output debug_match_count <== match_sum;
    
    // Output both top distances for each query
    signal output query0_best_distance <== top_matches[0][0][1];
    signal output query0_second_distance <== top_matches[0][1][1];
    signal output query1_best_distance <== top_matches[1][0][1];
    signal output query1_second_distance <== top_matches[1][1][1];
    
    // Output indices of matches
    signal output query0_best_index <== top_matches[0][0][0];
    signal output query0_second_index <== top_matches[0][1][0];
    signal output query1_best_index <== top_matches[1][0][0];
    signal output query1_second_index <== top_matches[1][1][0];
}

component main = FingerprintVerifier();
