#!/bin/bash
echo "XOR - преобразование файла. Выполнил студент РИ-581223 Зинченко Сергей"
echo "<имя исходного файла> <ключ-файл> <имя преобразованного файла>"
#read -r infile maskfile outfile
infile=text.txt
maskfile=test_key
outfile=out.txt

if [ -e ./"$infile" ] && [ -e ./"$maskfile" ] && [ ! -z  "$outfile" ]; then
	hexdump_infile=$(xxd -g 1 -i "$infile")

# Из man xxd:
# xxd  -  создаёт  представление файла в виде шестнадцатеричных кодов или выполняет обратное преобразование.
# -g позволяет выполнять группировку указанного количества <байтов> шестнадцатеричные  цифры или восемь битов), отделяя группы друг от друга пробелами.
# -i позволяет создавать вывод в стиле подключаемых заголовочных файлов языка C. Вывод содержит полноценное определение статического массива данных,
#    имя которого соответствует имени входного файла, если xxd не считывает данные из потока стандартного ввода.

	hexdump_maskfile=$(xxd -g 1 -i "$maskfile")
	hexdump_outfile=""
	echo "$hexdump_infile"
#	echo "$hexdump_maskfile"
	len_hexdump_infile=$(echo "$hexdump_infile" | wc -l)
	len_hexdump_maskfile=$(echo "$hexdump_maskfile" | wc -l)

	n=1
	m=2
	l=0

	while IFS= read -r line
	do

	if [ $n -eq 1 ] || [ $n -gt $(( $len_hexdump_infile - 2 )) ]; then
		hexdump_outfile+="$line"$'\n'""
		let n++
	else
		line="$(echo -e "${line}" | tr -d '[:space:]')"
		IFS=',' read -a array_infile <<< $line

		mask_line=$(sed -n ${m}p <<< "$hexdump_maskfile" | tr -d '[:space:]')
		IFS=',' read -a array_maskfile <<< $mask_line

#		echo "$line"
#		echo "$mask_line"

		len_array_infile=$(echo ${#array_infile[@]})
		len_array_maskfile=$(echo ${#array_maskfile[@]})

		k=0
		out_line=" "

		for elem_line in "${array_infile[@]}"; do

			if [ $(( $l + 1 )) -gt $len_array_maskfile ]; then
#				echo "Сброс индекса"
				let m++
				l=0
				if [ $m -gt $(( $len_hexdump_maskfile - 2 )) ]; then
#					echo "Сброс в начало"
					m=2
				fi
				mask_line=$(sed -n ${m}p <<< "$hexdump_maskfile" | tr -d '[:space:]')
				IFS=',' read -a array_maskfile <<< $mask_line
				len_array_maskfile=$(echo ${#array_maskfile[@]})
			fi

			buff=$(printf '%x\n' "$(( ${array_infile[$k]} ^ ${array_maskfile[$l]} ))")

			if [ ${#buff} -eq 1 ]; then
				sum="0x0"
			else
				sum="0x"
			fi

			sum+="$buff"
#			echo "${array_infile[$k]} ^ ${array_maskfile[$l]} = $sum"
			out_line+=" $sum,"

			let k++
			let l++
		done

		hexdump_outfile+="$out_line"$'\n'""
		let n++
	fi
	done < <(printf '%s\n' "$hexdump_infile")
	hexdump_outfile=$(echo "$hexdump_outfile" | head -n -1)
#	echo "$hexdump_outfile"
	res=$(xxd -r -p <<<"$hexdump_outfile")
	res="${res:1: -2}"
	echo "$res" > $outfile
else
	echo "Данные введены некорректно!"
fi