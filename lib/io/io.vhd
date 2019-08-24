LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
USE lib.numeric.All;

LIBRARY lib;
USE lib.io.ALL;
-- Pacote com as funções e componentes relacionadas às operações de entrada e
-- saída da calculadora.
PACKAGE io IS

	-- Constante utilizada para definir um valor de entrada que não
	-- seja utilizado pela calculadora.
	CONSTANT IGNORED : STD_LOGIC_VECTOR(4 DOWNTO 0) := "11111";

	-- Função que verifica se o código de entrada representa um valor numérico.
	-- Entrada: um vetor de 5 bits do tipo STD_LOGIC_VECTOR representando um
	-- código de entrada da calculadora.
	-- Saída: um valor do tipo BOOLEAN que representa se o valor de entrada é
	-- numérico ou não.
	FUNCTION is_number(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN;

	-- Função que verifica se o código de entrada representa um possível código de
	-- operador (+, -, * ou /) da calculadora.
	-- Entrada: um vetor de 5 bits do tipo STD_LOGIC_VECTOR representando um
	-- código de entrada da calculadora.
	-- Saída: um valor do tipo BOOLEAN que representa se o valor de entrada é
	-- um operador ou não.
	FUNCTION is_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN;

	-- Função que verifica se o código de entrada representa um operador de soma ou
	-- subtração.
	-- Entrada: um vetor de 5 bits do tipo STD_LOGIC_VECTOR representando um
	-- código de entrada da calculadora.
	-- Saída: um valor do tipo BOOLEAN que representa se o valor de entrada é
	-- é um operador simples (soma ou subtração) ou não.
	FUNCTION is_simple_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN;

	-- Função que verifica se o código de entrada representa um operador de
	-- multiplicação ou divisão.
	-- Entrada: um vetor de 5 bits do tipo STD_LOGIC_VECTOR representando um
	-- código de entrada da calculadora.
	-- Saída: um valor do tipo BOOLEAN que representa se o valor de entrada é
	-- é um operador complexo (multiplicação ou divisão) ou não.
	FUNCTION is_complex_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN;

	-- Função que retorna um valor para o display deslocando o valor do display
	-- atual para uma casa decimal a esquerda e adicionando um valor de entrada
	-- numérico (de 0 a 9) na primeira casa decimal.
	-- Entrada: 1. um vetor de N bits do tipo STD_LOGIC_VECTOR que representa o
	--             valor numérico atual mostrado nos displays de 7 segmentos.
	--          2. um vetor de 4 bits do tipo STD_LOGIC_VECTOR representando um
	--             valor numérico entre 0 e 9 que será adicionado a primeira casa
	--             decimal do valor do display atual.
	-- Saída: um vetor de N bits com o valor mostrado nos displays de 7 segmentos
	-- com uma nova casa decimal.
	FUNCTION get_resulting_display(display : STD_LOGIC_VECTOR(N-1 DOWNTO 0); input : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;

	-- Componente que interpreta e transmite os pacotes com os comandos utilizados
	-- pelo teclado.
	-- Sinais bidirecionais:
	--		ps2_data: corresponde aos bits transferidos serialmente para e da porta PS2.
	-- 	ps2_clock: é o clock de funcionamento do controlador PS2.
	-- Entradas:
	-- 	clk: corresponde ao clock do sistema. Deve ter a mesma frequência atribuída
	--         ao clkfreq, 24000 (kHz).
	-- 	en: sinal de habilitação (ativo em nível baixo.
	-- 	resetn: sinal de reinicialização (ativo em nível baixo).
	-- 	lights: é um vetor que determina o estado dos LEDs do teclado: light(0) é o
	-- 	        do scroll lock, light(1) é o do nunlock e o lights(2) o do capslock.
	-- Saídas:
	-- 	key_on: é um vetor que indica se temos ou não teclas pressionadas. O índice 0
	-- 	        representa a primeira tecla pressionada, o 1 a segunda e o 2 a terceira.
	-- 	Key_code: é o vetor que indica o código de leitura (scancode) das teclas
	-- 				 pressionadas. Os bits 15-0 representam a primeira tecla pressionada;
	-- 				 os bits 31-16 representam a segunda tecla pressionada; e os bits 47-32
	-- 				 representam a segunda tecla pressionada.
	COMPONENT kbdex_ctrl
		GENERIC(
			clkfreq : INTEGER
		);
		PORT(
			ps2_data		:	INOUT	STD_LOGIC;
			ps2_clk		:	INOUT	STD_LOGIC;
			clk			:	IN 	STD_LOGIC;
			en				:	IN 	STD_LOGIC;
			resetn		:	IN 	STD_LOGIC;
			lights		: 	IN	STD_LOGIC_VECTOR(2 DOWNTO 0); -- lights(Caps, Nun, Scroll)
			key_on		:	OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			key_code		:	OUT	STD_LOGIC_VECTOR(47 DOWNTO 0)
		);
	END COMPONENT;
END io;

PACKAGE BODY io IS
	FUNCTION is_number(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN IS
	BEGIN
		RETURN calc_input(4) = '0';
	END is_number;

	FUNCTION is_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN IS
	BEGIN
		RETURN calc_input(4) = '1' AND calc_input /= IGNORED;
	END is_operation;

	FUNCTION is_simple_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN IS
	BEGIN
		RETURN calc_input(4 DOWNTO 3) = "10";
	END is_simple_operation;

	FUNCTION is_complex_operation(calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0)) RETURN BOOLEAN IS
	BEGIN
		RETURN calc_input(4 DOWNTO 3) = "11" AND calc_input /= IGNORED;
	END is_complex_operation;

	FUNCTION get_resulting_display(display : STD_LOGIC_VECTOR(N-1 DOWNTO 0); input : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
		-- Variável temporária utilizada para armazenar o resultado da multiplicação
		-- do valor atual do display multiplicado por 10.
		VARIABLE lr : STD_LOGIC_VECTOR(N+N-1 DOWNTO 0);

		-- Constante com o valor decimal 10 em binário.
		CONSTANT TEN : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(10,N));

		-- Variável utilizada para armazenar se o resultado da soma excedeu o valor
		-- máximo possível.
		VARIABLE overflow : STD_LOGIC;

		-- Variáveis temporárias utilizadas para armazenar os valores do número atual
		-- do display multiplicado por 10 e o valor de entrada ambas com o tamanho de
		-- N bits.
		VARIABLE a, b : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

		VARIABLE display_out : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	BEGIN
		-- Multiplica o valor atual do display por 10 para deslocar o valor do display
		-- para uma casa decimal a esquerda.
		lr :=  booth_multiplier(TEN, display);

		-- Transforma o valor do resultado anterior e o número de entrada para o
		-- tamanho de N bits.
		a := (OTHERS => '0');
		a := lr(N-1 DOWNTO 0);
		--a := STD_LOGIC_VECTOR(RESIZE(UNSIGNED(lr), N));

		b := (OTHERS => '0');
		b(3 DOWNTO 0) := input;
		--b := STD_LOGIC_VECTOR(RESIZE(UNSIGNED(input), N));

		-- Verifica se o valor do display deslocado uma casa decimal a esquerda
		-- excede o valor máximo de 13 bits de um número binário de complemento de 2.
		IF (lr <= MAX_VALUE) THEN

			-- Adiciona o valor decimal de 0 a 9 a primeira casa decimal do número do
			-- display deslocado uma casa decimal a esquerda.
			ripple_adder_subtractor(a, b,	'1', display_out, overflow);

			-- Verifica se o valor do display deslocado uma casa decimal a esquerda
			-- e adicionado um dígito na primeira casa decimal excede o valor máximo
			-- de 13 bits de um número binário de complemento de 2. Caso o valor
			-- exceda o limite máximo é retornado o mesmo número binário de entrada.
			IF (overflow = '1') THEN
				RETURN display;
			ELSE
				RETURN display_out;
			END IF;

		ELSE
			RETURN display;
		END IF;

	END get_resulting_display;

END io;
