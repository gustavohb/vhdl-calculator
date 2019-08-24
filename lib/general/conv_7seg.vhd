LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

-- Entidade responsável pela conversão de um código binário para representação
-- no display de 7 segmentos. Os valores de bit "1110" e "1111" são reservados,
-- respectivamente, para a representação do símbolo negativo e quando o display
-- está apagado.
-- Entrada: um valor binário de 4 bits do tipos STD_LOGIC_VECTOR.
-- Saída: um vetor de 7 bits do tipo STD_LOGIC_VECTOR com as informações para um
-- display de 7 segmentos.
ENTITY conv_7seg IS
	port( digit	: in STD_LOGIC_VECTOR (3 downto 0);
			seg	: out STD_LOGIC_VECTOR (6 downto 0));
END conv_7seg;

ARCHITECTURE structural OF conv_7seg IS
BEGIN
	WITH digit SELECT
		seg <= "1000000" WHEN "0000", -- 0
				 "1111001" WHEN "0001", -- 1
				 "0100100" WHEN "0010", -- 2
				 "0110000" WHEN "0011", -- 3
				 "0011001" WHEN "0100", -- 4
				 "0010010" WHEN "0101", -- 5
				 "0000010" WHEN "0110", -- 6
				 "1011000" WHEN "0111", -- 7
				 "0000000" WHEN "1000", -- 8
				 "0010000" WHEN "1001", -- 9
				 "0111111" WHEN "1110", -- NEG SIGN
				 "1111111" WHEN "1111", -- BLANK
				 "1111111" WHEN OTHERS;
END structural;
