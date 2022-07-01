#!/usr/bin/env bash

shopt -s nullglob

declare -a test_sources=( tests/*.c )
declare -a generators=( clang retdec )
declare -a decompilers=( retdec rellic )

echo "Test name,Generator,Decompiler,Output differs,Exit code differs" > "$OUTPUT_DIR/results.csv"

for test_file in "${test_sources[@]}"
do
    base_name=$(basename "$test_file")
    base_name_no_suffix="${base_name:0:-2}"
    
    $CLANG_C "$test_file" -o "$OUTPUT_DIR/$base_name_no_suffix"
    $CLANG_LL -S -emit-llvm "$test_file" -o "$OUTPUT_DIR/$base_name_no_suffix.clang.ll"
    $RETDEC "$OUTPUT_DIR/$base_name_no_suffix" --stop-after=bin2llvmir -o "$OUTPUT_DIR/$base_name_no_suffix.retdec.ll"
    cat <(echo 'target triple = "x86_64-pc-linux-gnu"') "$OUTPUT_DIR/$base_name_no_suffix.retdec.ll" > "$OUTPUT_DIR/$base_name_no_suffix.retdec.fix.ll"
    $RETDEC "$OUTPUT_DIR/$base_name_no_suffix.clang.ll" --no-config -o "$OUTPUT_DIR/$base_name_no_suffix.clang.retdec.c"
    $RETDEC "$OUTPUT_DIR/$base_name_no_suffix.retdec.ll" --no-config -o "$OUTPUT_DIR/$base_name_no_suffix.retdec.retdec.c"
    $RELLIC --input "$OUTPUT_DIR/$base_name_no_suffix.clang.ll" --output "$OUTPUT_DIR/$base_name_no_suffix.clang.rellic.c"
    $RELLIC --input "$OUTPUT_DIR/$base_name_no_suffix.retdec.fix.ll" --output "$OUTPUT_DIR/$base_name_no_suffix.retdec.rellic.c"

    "$OUTPUT_DIR/$base_name_no_suffix" > "$OUTPUT_DIR/${base_name_no_suffix}_out"
    reference_code=$?

    for gen in "${generators[@]}"
    do
        for dec in "${decompilers[@]}"
        do
            target_file="$OUTPUT_DIR/$base_name_no_suffix.${gen}.${dec}"
            if [[ -f "$target_file.c" ]]; then
                $CLANG_C -Wno-everything -w "$target_file.c" -o "$target_file"

                if [[ -f "$target_file" ]]; then
                    "${target_file}" > "${target_file}_out"
                    code=$?

                    if [[ $reference_code -eq $code ]]; then
                        code_differs="FALSE"
                    else
                        code_differs="TRUE"
                    fi

                    if diff "$OUTPUT_DIR/${base_name_no_suffix}_out" "${target_file}_out"; then
                        output_differs="FALSE"
                    else
                        output_differs="TRUE"
                    fi

                    echo "${base_name_no_suffix},$gen,$dec,$output_differs,$code_differs" >> "$OUTPUT_DIR/results.csv"
                else
                    echo "${base_name_no_suffix},$gen,$dec,Did not compile" >> "$OUTPUT_DIR/results.csv"
                fi
            else
                echo "${base_name_no_suffix},$gen,$dec,Did not decompile" >> "$OUTPUT_DIR/results.csv"
            fi
        done
    done
done
