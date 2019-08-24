LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;

-- Pacote que contém as constantes e funções numéricas utilizadas pela calculadora.
PACKAGE numeric IS

	-- Define a quantidade máxima de bits para os números da calculadora.
	CONSTANT N : INTEGER := 13;

	-- Constantes utilizadas para a representação dos operadores e comandos
	-- possíveis da calculadora.
	CONSTANT SUM 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "10001";
	CONSTANT SUB 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "10010";
	CONSTANT MUL 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "11001";
	CONSTANT DIV 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "11010";
	CONSTANT ENTER : STD_LOGIC_VECTOR(4 DOWNTO 0) := "11101";
	CONSTANT RES 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "11100"; -- RESET

	-- Constante utilizada para representar o valor zero de N bits em binário.
	CONSTANT ZERO : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');

	-- Constantes com o valor máximo e mínimo operado pela calculadora.
	CONSTANT MAX_VALUE : INTEGER := 	4095; -- 0111111111111
	CONSTANT MIN_VALUE : INTEGER := -4096; -- 1000000000000

	-- Função que define a operação de multiplicação utilizando função da biblioteca
	-- numeric_std
	FUNCTION divide(a : STD_LOGIC_VECTOR; b : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;

	-- Função que define a operação de multiplicação utilizando o algoritmo de
	-- Booth melhorado.
	-- Entradas: 1. Vetor de 13 bits do tipo STD_LOGIC_VECTOR representando o
	--              multiplicando.
	--           2. Vetor de 13 bits do tipo STD_LOGIC_VECTOR representando o
	--              multiplicador.
	-- Saída: Vetor de N + N - 1 bits do tipo STD_LOGIC_VECTOR com o resultado da
	-- operação de multiplicação.
	FUNCTION booth_multiplier(x : STD_LOGIC_VECTOR(N-1 DOWNTO 0); y : STD_LOGIC_VECTOR(N-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;

	-- Procedimento responsável pela operação numérica da calculadora.
	-- Entradas: 1. Vetor de N bits do tipo STD_LOGIC_VECTOR representando primeiro
	--              operando da operação.
	--           2. Vetor de N bits do tipo STD_LOGIC_VECTOR representando segundo
	--              operando da operação.
	--           3. Vetor de 5 bits do tipo STD_LOGIC_VECTOR representando um
	--              possível operador.
	-- Saídas: 1. Vetor de N bits do tipo STD_LOGIC_VECTOR representando o resultado
	--            da operação.
	--         2. Um bit do tipo STD_LOGIC indicando se ocorreu algum tipo de erro
	--            na operação.
	PROCEDURE evaluate(VARIABLE a : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 VARIABLE b : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 CONSTANT op : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
							 VARIABLE result : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 VARIABLE error : OUT STD_LOGIC);

	-- Procedimento responsável pelas operações de soma ou subtração.
	-- Entradas: 1. Vetor de N bits do tipo STD_LOGIC_VECTOR representando primeiro
	--              operando da operação.
	--           2. Vetor de N bits do tipo STD_LOGIC_VECTOR representando segundo
	--              operando da operação.
	--           3. Um bit indicando o tipo de operação (1 = soma, 0 = subtração)
	-- Saídas: 1. Vetor de N bits do tipo STD_LOGIC_VECTOR representando o resultado
	--            da operação.
	-- 				 2. Um bit do tipo STD_LOGIC indicando se ocorreu overflow na operação.
	PROCEDURE ripple_adder_subtractor(VARIABLE a : IN STD_LOGIC_VECTOR;
												 VARIABLE b : IN STD_LOGIC_VECTOR;
												 CONSTANT add_sub : IN STD_LOGIC := '1';
												 VARIABLE y : OUT STD_LOGIC_VECTOR;
												 VARIABLE overflow : OUT STD_LOGIC);

	-- Procedimento responsável pela operação de soma ou subtração de apenas um bit.
	-- Entradas: 1. Um bit do tipo STD_LOGIC representando o primeiro operando.
	--           2. Um bit do tipo STD_LOGIC representando o segundo operando.
	--           3. Um bit do tipo STD_LOGIC representando o valor de entrada do
	--              carry.
	--           4. Um bit indicando o tipo de operação (1 = soma, 0 = subtração)
	-- Saídas: 1. Um bit do tipo STD_LOGIC representando o resultado da operação.
	--         2. Um bit do tipo STD_LOGIC representando o valor de saída do
	--              carry.
	PROCEDURE bit_adder_subtractor(CONSTANT a : IN STD_LOGIC;
											 CONSTANT b : IN STD_LOGIC;
											 CONSTANT cin : IN STD_LOGIC;
											 CONSTANT add_sub : IN STD_LOGIC;
											 VARIABLE y : OUT STD_LOGIC;
											 VARIABLE cout : OUT STD_LOGIC);

END numeric;

PACKAGE BODY numeric IS

	PROCEDURE evaluate(VARIABLE a : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 VARIABLE b : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 CONSTANT op : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
							 VARIABLE result : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
							 VARIABLE error : OUT STD_LOGIC) IS

	-- Variáveis temporárias utilizadas para armazenar os valores
	-- de resultados de operações intermediária
	VARIABLE localresult : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	VARIABLE tempresult : STD_LOGIC_VECTOR(N+N-1 DOWNTO 0);
	-- Variável utilizada para indicar a ocorrência de overflow
	VARIABLE overflow : STD_LOGIC;

	BEGIN
		-- Inicializa error como zero (sem ocorrência de erro)
		error := '0';
		-- Verifica se operação é de soma.
		IF (op = SUM) THEN

			ripple_adder_subtractor(a, b, '1', localresult, overflow);

			IF (overflow = '1') THEN
				error := '1';
			END IF;
			result := localresult;

		-- Verifica se operação é de subtração.
		ELSIF (op = SUB) THEN

			ripple_adder_subtractor(a, b, '0', localresult, overflow);

			IF (overflow = '1') THEN
				error := '1';
			END IF;
			result := localresult;

		-- Verifica se operação é de multiplicação.
		ELSIF (op = MUL) THEN
			tempresult := booth_multiplier(a, b);

			IF (SIGNED(tempresult) > MAX_VALUE) THEN
				error := '1';
			ELSIF (SIGNED(tempresult) < MIN_VALUE) THEN
				error := '1';
			END IF;
			result := STD_LOGIC_VECTOR(RESIZE(SIGNED(tempresult), result'LENGTH));

		-- Verifica se operação é de divisão.
		ELSIF (op = DIV) THEN
			IF (b = ZERO) THEN
				-- Retorna erro caso o divisor seja zero
				error := '1';
			ELSE
				result := divide(a,b);
			END IF;
		ELSE
			result := ZERO;
			error := '1';
		END IF;
	END evaluate;

	PROCEDURE bit_adder_subtractor(CONSTANT a : IN STD_LOGIC;
							  CONSTANT b : IN STD_LOGIC;
							  CONSTANT cin : IN STD_LOGIC;
							  CONSTANT add_sub : IN STD_LOGIC;
							  VARIABLE y : OUT STD_LOGIC;
							  VARIABLE cout : OUT STD_LOGIC) IS
	VARIABLE b_sig : STD_LOGIC;

	BEGIN
		IF (add_sub = '0') THEN
			b_sig := NOT b;
		ELSE
			b_sig := b;
		END IF;

		y := a XOR b_sig XOR cin;

		cout := (a AND b_sig) OR
				  (a AND cin) OR
				  (b_sig AND cin);

	END bit_adder_subtractor;

	PROCEDURE ripple_adder_subtractor(VARIABLE a : IN STD_LOGIC_VECTOR;
												 VARIABLE b : IN STD_LOGIC_VECTOR;
												 CONSTANT add_sub : IN STD_LOGIC := '1';
												 VARIABLE y : OUT STD_LOGIC_VECTOR;
												 VARIABLE overflow : OUT STD_LOGIC) IS
	VARIABLE carry : STD_LOGIC_VECTOR(a'RANGE);
	VARIABLE temp_result : STD_LOGIC_VECTOR(a'RANGE);
	BEGIN

		bit_adder_subtractor(a(0), b(0), NOT add_sub, add_sub, temp_result(0), carry(0));

		FOR i IN 1 TO a'LENGTH -1 LOOP
			bit_adder_subtractor(a(i), b(i), carry(i-1), add_sub, temp_result(i), carry(i));
		END LOOP;

		overflow := carry(a'LENGTH-1) XOR carry(a'LENGTH-2);

		y := temp_result;

	END ripple_adder_subtractor;

	FUNCTION booth_multiplier(x : STD_LOGIC_VECTOR(N-1 DOWNTO 0); y : STD_LOGIC_VECTOR(N-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS

	VARIABLE result : STD_LOGIC_VECTOR(N + N - 1 DOWNTO 0);
	VARIABLE a, s, p : STD_LOGIC_VECTOR(N + N + 1 DOWNTO 0);
	VARIABLE nx : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	VARIABLE overflow : STD_LOGIC;
	CONSTANT z : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
	BEGIN

		a := (OTHERS => '0');
		s := (OTHERS => '0');
		P := (OTHERS => '0');

		a(N+N DOWNTO N+1) := x;
		a(N+N+1) := x(N-1);

		nx := (NOT x) + 1;
		s(N+N DOWNTO N+1) := nx;
		s(N+N+1) := NOT(x(N-1));

		-- Somente executa o algoritmo de Booth se o multiplicador e o multiplicando
		-- são diferentes de zero.
		IF (x /= z AND y /= z) THEN
			p(N DOWNTO 1) := y;
			FOR i IN 0 TO N-1 LOOP
				IF (p(1 DOWNTO 0) = "01") THEN
					ripple_adder_subtractor(p, a, '1', p, overflow);
				ELSIF (p(1 DOWNTO 0) = "10") THEN
					ripple_adder_subtractor(p, s, '1', p, overflow);
				END IF;
				p(N+N DOWNTO 0) := p(N+N+1 DOWNTO 1);
			END LOOP;
		END IF;

		result := p(N+N DOWNTO 1);
		RETURN result;
	END booth_multiplier;

	FUNCTION divide(a : STD_LOGIC_VECTOR; b : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
	BEGIN
		-- TODO
		RETURN STD_LOGIC_VECTOR(SIGNED(a) / SIGNED(b));
	END divide;

END numeric;
