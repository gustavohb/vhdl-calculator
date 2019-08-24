LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

-- Conversão de um número binário para codificação binária decimal (BCD)
-- utilizando o algoritmo double dabble.
-- Entrada: um número binário de 13 bits do tipo STD_LOGIC_VECTOR no formato de
-- complemento de 2.
-- Saídas: quatro números binários de 4 bits do tipo STD_LOGIC_VECTOR.
-- Cada número corresponde a uma casa decimal distinta. O número de saída no
-- formato BCD é seu valor absoluto. Caso seja negativo e o número não utilize
-- todas as 4 casas decimais, o display de 7 segmentos da primeira casa decimal
-- mais a esquerda do número exibe o sinal negativo.
ENTITY binary_to_bcd IS
	PORT (binary : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
			bcd_uni : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_ten : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_hun : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_tho : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
END binary_to_bcd;

ARCHITECTURE binary_to_bcd_arch OF binary_to_bcd IS
BEGIN

	PROCESS(binary) IS

	VARIABLE bcd : STD_LOGIC_VECTOR(15 DOWNTO 0);
	VARIABLE abs_num : STD_LOGIC_VECTOR(12 DOWNTO 0);

	-- Constantes definidas para representar o valor zero (ZERO), um display
	-- apagado (BLANK) e o símbolo negativo (NEG_SIGN).
	CONSTANT ZERO : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
	CONSTANT BLANK : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111";
	CONSTANT NEG_SIGN : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1110";

	BEGIN
		-- Se o número binário de entrada for negativo, obtém-se o valor absoluto
		-- utilizando o operador NOT e somando mais um no resultado. Considera-se
		-- aqui que o número binário esteja no formato de complemento de 2.
		IF (binary(12) = '1') THEN
			abs_num := STD_LOGIC_VECTOR(UNSIGNED((NOT binary) + 1));
		ELSE
			abs_num := binary;
		END IF;

		-- Inicializa bcd com zeros em todos os bits.
		bcd := (OTHERS => '0');

		-- Laço for utilizando o algoritmo double dabble.
		FOR i IN 0 TO 12 LOOP

			IF (bcd(3 DOWNTO 0) > 4) THEN
				bcd(3 DOWNTO 0) := bcd(3 DOWNTO 0) + 3;
			END IF;

			IF (bcd(7 DOWNTO 4) > 4) THEN
				bcd(7 DOWNTO 4) := bcd(7 DOWNTO 4) + 3;
			END IF;

			IF (bcd(11 DOWNTO 8) > 4) THEN
				bcd(11 DOWNTO 8) := bcd(11 DOWNTO 8) + 3;
			END IF;

			-- Desloca para esquerda.
			bcd := bcd(14 DOWNTO 0) & abs_num(12-i);

		END LOOP;

		-- Verifica se as últimas casas decimais do número são iguais a zero.
		-- Caso isso ocorra, as casas decimais que não possuem valor são definidas
		-- como BLANK, fazendo com que o display de 7 segmento não mostre valor algum.
		IF (bcd(15 DOWNTO 12) = ZERO AND bcd(11 DOWNTO 8) = ZERO AND bcd(7 DOWNTO 4) = ZERO) THEN
			bcd(15 DOWNTO 12) := BLANK;
			bcd(11 DOWNTO 8) := BLANK;

			IF (binary(12) = '1') THEN
				bcd(7 DOWNTO 4) := NEG_SIGN;
			ELSE
				bcd(7 DOWNTO 4) := BLANK;
			END IF;

		ELSIF (bcd(15 DOWNTO 12) = ZERO AND bcd(11 DOWNTO 8) = ZERO AND bcd(7 DOWNTO 4) /= ZERO) THEN
			bcd(15 DOWNTO 12) := BLANK;

			IF (binary(12) = '1') THEN
				bcd(11 DOWNTO 8) := NEG_SIGN;
			ELSE
				bcd(11 DOWNTO 8) := BLANK;
			END IF;

		ELSIF (bcd(15 DOWNTO 12) = ZERO AND bcd(11 DOWNTO 8) /= ZERO) THEN

			IF (binary(12) = '1') THEN
				bcd(15 DOWNTO 12) := NEG_SIGN;
			ELSE
				bcd(15 DOWNTO 12) := BLANK;
			END IF;

		END IF;

		bcd_uni <= bcd(3 DOWNTO 0);
		bcd_ten <= bcd(7 DOWNTO 4);
		bcd_hun <= bcd(11 DOWNTO 8);
		bcd_tho <= bcd(15 DOWNTO 12);

	END PROCESS;

END binary_to_bcd_arch;
