LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entidade responsável pela conversão dos scancodes do teclado para um formato
-- interno utilizado pela calculadora.
-- Entrada: um vetor de 8 bits do tipo STD_LOGIC_VECTOR representando o valor
-- scancode do teclado.
-- Saída: um vetor de 4 bits do tipo STD_LOGIC_VECTOR representando os
-- números de 0 a 9, as teclas +, -, *, /, enter e esc. O valor "11111"
-- representa um valor qualquer que não seja utilizado pela calculadora.
ENTITY scancode_to_calc_input IS
	PORT(scancode : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		  calc_input : OUT STD_LOGIC_VECTOR(4 DOWNTO 0));
END scancode_to_calc_input;

ARCHITECTURE scancode_to_calc_input_arch OF scancode_to_calc_input IS
BEGIN
	WITH scancode SELECT
		calc_input <= "00000" WHEN x"70" | x"45", -- "01110000", -- 0	70
						  "00001" WHEN x"69" | x"16", -- "01101001", -- 1	69
						  "00010" WHEN x"72" | x"1E", -- "01110010", -- 2	72
						  "00011" WHEN x"7A" | x"26", -- "01111010", -- 3	7A
						  "00100" WHEN x"6B" | x"25", -- "01101011", -- 4	6B
						  "00101" WHEN x"73" | x"2E", -- "01110011", -- 5	73
						  "00110" WHEN x"74" | x"36", -- "01110100", -- 6	74
						  "00111" WHEN x"6C" | x"3D", -- "01101100", -- 7	6C
						  "01000" WHEN x"75" | x"3E",  -- "01110101", -- 8	75
						  "01001" WHEN x"7D" | x"46", -- "01111101", -- 9	7D
						  "10001" WHEN x"79", -- "01111001", -- +	79
						  "10010" WHEN x"7B", -- "01111011", -- -	7B
						  "11001" WHEN x"7C", -- "01111100", -- *	7C
						  "11010" WHEN x"4A", -- "01001010", -- /	4A
						  "11101" WHEN x"5A", -- ENTER "01011010", -- En	5A
						  "11100" WHEN x"76", -- ESC
						  "11111" WHEN OTHERS; -- INVALID
END scancode_to_calc_input_arch;
