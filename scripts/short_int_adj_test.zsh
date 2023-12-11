#!/usr/bin/env zsh

set -ex

disable -r time

# cargo build --release --features r1cs,smt,zok,bellman --example circ
# cargo build --release --features r1cs,smt,zok,bellman --example zk

MODE=release # debug or release
BIN=./target/$MODE/examples/circ
ZK_BIN=./target/$MODE/examples/zk

case "$OSTYPE" in 
    darwin*)
        alias measure_time="gtime --format='%e seconds %M kB'"
    ;;
    linux*)
        alias measure_time="time --format='%e seconds %M kB'"
    ;;
esac

# Test prove workflow, given an example name
function pf_test {
    for proof_impl in groth16
    do
        ex_name=$1
        $BIN examples/ZoKrates/pf/$ex_name.zok --short-int-adj --write-output r1cs --action setup --proof-impl $proof_impl
        $ZK_BIN --inputs examples/ZoKrates/pf/$ex_name.zok.pin --action prove --proof-impl $proof_impl
        $ZK_BIN --inputs examples/ZoKrates/pf/$ex_name.zok.vin --action verify --proof-impl $proof_impl
        rm -rf P V pi
        $BIN examples/ZoKrates/pf/$ex_name.zok --write-output r1cs --action setup --proof-impl $proof_impl
    done
}

function pf_test_isolate {
    for proof_impl in groth16 mirage
    do
        ex_name=$1
        $BIN --zsharp-isolate-asserts true examples/ZoKrates/pf/$ex_name.zok --short-int-adj --write-output r1cs --action setup --proof-impl $proof_impl
        $ZK_BIN --inputs examples/ZoKrates/pf/$ex_name.zok.pin --action prove --proof-impl $proof_impl
        $ZK_BIN --inputs examples/ZoKrates/pf/$ex_name.zok.vin --action verify --proof-impl $proof_impl
        rm -rf P V pi
        $BIN --zsharp-isolate-asserts true examples/ZoKrates/pf/$ex_name.zok --write-output r1cs --action setup --proof-impl $proof_impl
    done
}

function pf_test_only_pf {
    for proof_impl in groth16
    do
        ex_name=$1
        $BIN examples/ZoKrates/pf/$ex_name.zok --short-int-adj --write-output r1cs --action setup --proof-impl $proof_impl
        $ZK_BIN --inputs examples/ZoKrates/pf/$ex_name.zok.pin --action prove --proof-impl $proof_impl
        rm -rf P V pi
        $BIN examples/ZoKrates/pf/$ex_name.zok --write-output r1cs --action setup --proof-impl $proof_impl

    done
}

function r1cs_test {
    zpath=$1
    measure_time $BIN $zpath --short-int-adj --write-output r1cs --action count
    measure_time $BIN $zpath --write-output r1cs --action count

}

# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/ecc/edwardsAdd.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/ecc/edwardsOnCurve.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/ecc/edwardsOrderCheck.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/ecc/edwardsNegate.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/multiplexer/lookup1bit.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/multiplexer/lookup2bit.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/multiplexer/lookup3bitSigned.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/casts/bool_128_to_u32_4.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/pack/u32/pack128.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/utils/pack/bool/pack128.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/ecc/edwardsScalarMult.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/hashes/mimc7/mimc7R20.zok
# r1cs_test ./third_party/ZoKrates/zokrates_stdlib/stdlib/hashes/pedersen/512bit.zok
# r1cs_test ./test.zok
r1cs_test ./testadd.zok
# rm ./short_int_adj_benchmark.txt
# for file in $(find "../Zombie/circ/zkmb" -type f); 
# do
#     if [[ $file =~ .*\.(zok$|zok$) ]] 
#         then 
#             # echo "$file"
#             echo "$file" >> ./short_int_adj_benchmark.txt
#             r1cs_test "$file" || :
#     fi
# done
# r1cs_test ../Zombie/circ/zkmb/LabelExtraction.zok
# r1cs_test ../Zombie/circ/zkmb/DohChaChaAmortized.zok
# r1cs_test ../Zombie/circ/zkmb/policy6471.zok
# r1cs_test ../Zombie/circ/zkmb/DohAESAmortized.zok
# r1cs_test ../Zombie/circ/zkmb/tls_key_schedules/tls_key_schedule.zok
# r1cs_test ../Zombie/circ/zkmb/AESChannelOpen.zok
# r1cs_test ../Zombie/circ/zkmb/ChaCha_template.zok
# r1cs_test ../Zombie/circ/zkmb/DohAESAmortizedUnpack.zok
# r1cs_test ../Zombie/circ/zkmb/test.zok
# r1cs_test ../Zombie/circ/zkmb/ChaChaChannelOpen.zok

# pf_test_only_pf sha_temp1
# pf_test_only_pf sha_rot
# pf_test_only_pf maj
# pf_test_only_pf sha_temp2
# pf_test_only_pf test_sha256

# pf_test assert
# pf_test assert2
# pf_test_isolate isolate_assert
# pf_test 3_plus
# pf_test xor
# pf_test mul
# pf_test many_pub
# pf_test str_str
# pf_test str_arr_str
# pf_test arr_str_arr_str
# pf_test var_idx_arr_str_arr_str
# pf_test mm
