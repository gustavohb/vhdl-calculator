LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Pacote com os componentes gerais que são utilizados no projeto.
PACKAGE general IS

	-- Componente responsável pela conversão de um código binário para representação
	-- no display de 7 segmentos. Os valores de bit "1110" e "1111" são reservados,
	-- respectivamente, para a representação do símbolo negativo e quando o display
	-- está apagado.
	-- Entrada: um valor binário de 4 bits do tipos STD_LOGIC_VECTOR.
	-- Saída: um vetor de 7 bits do tipo STD_LOGIC_VECTOR com as informações para um
	-- display de 7 segmentos.
	COMPONENT conv_7seg
		PORT(
			digit		:		in STD_LOGIC_VECTOR (3 DOWNTO 0);
			seg	   :		out STD_LOGIC_VECTOR (6 DOWNTO 0)
		);
	END COMPONENT;

	-- Componente responsável pela geração do sinal PWM.
	-- Entradas: 1. sinal de clock
	--           2. sinal que indica se está o PWM habilitado.
	--           3. sinal de reset ativo em nível baixo.
	--           4. um vetor de 8 bits do tipo STD_LOGIC_VECTOR utilizado para o
	--              calculo do duty-cycle
	-- Saída: um bit do tipo STD_LOGIC que representa se o sinal PWM está ativo ou não.
	COMPONENT pwm
		PORT(
			clk 		: IN STD_LOGIC;
			enable 	: IN STD_LOGIC;
			rstn 		: IN STD_LOGIC;
			duty 		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			pwm_out 	: OUT STD_LOGIC
		);
	END COMPONENT;


	-- Componente responsável pela conversão de um número binário para codificação
	-- binária decimal (BCD) utilizando o algoritmo double dabble.
	-- Entrada: um número binário de 13 bits do tipo STD_LOGIC_VECTOR no formato de
	-- complemento de 2.
	-- Saídas: quatro números binários de 4 bits do tipo STD_LOGIC_VECTOR.
	-- Cada número corresponde a uma casa decimal distinta. O número de saída no
	-- formato BCD é seu valor absoluto. Caso seja negativo e o número não utilize
	-- todas as 4 casas decimais, o display de 7 segmentos da primeira casa decimal
	-- mais à esquerda do número exibe o sinal negativo.
	COMPONENT binary_to_bcd
		PORT(
			binary 	: IN STD_LOGIC_VECTOR(12 DOWNTO 0);
			bcd_uni 	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_ten 	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_hun 	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			bcd_tho 	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
		);
	END COMPONENT;

	-- Componente responsável pela conversão dos scancodes do teclado para um formato
	-- interno utilizado pela calculadora.
	-- Entrada: um vetor de 8 bits do tipo STD_LOGIC_VECTOR representando o valor
	-- scancode do teclado.
	-- Saída: um vetor de 4 bits do tipo STD_LOGIC_VECTOR representando os
	-- números de 0 a 9, as teclas +, -, *, /, enter e esc. O valor de saída
	-- "11111" representa um valor qualquer que não seja utilizado pela calculadora.
	COMPONENT scancode_to_calc_input IS
		PORT(
			scancode 	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			calc_input 	: OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
		);
	END COMPONENT;

END PACKAGE;
