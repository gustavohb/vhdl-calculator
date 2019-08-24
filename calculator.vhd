LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lib;
USE lib.io.ALL;
USE lib.general.ALL;
USE lib.numeric.ALL;

ENTITY calculator IS
	PORT
	(
		------------------------	Clock Input	 	------------------------
		clock_24	: 	IN	STD_LOGIC_VECTOR (1 DOWNTO 0);	--	24 MHz
		clock_27	:	IN	STD_LOGIC_VECTOR (1 DOWNTO 0);	--	27 MHz
		clock_50	: 	IN	STD_LOGIC;								--	50 MHz
		-- CLOCKTAP	: 	out	STD_LOGIC;

		------------------------	Push Button		------------------------
		key 	:		IN	STD_LOGIC_VECTOR (3 DOWNTO 0);		--	Pushbutton[3:0]

		------------------------	DPDT Switch		------------------------
		sw 	:		IN	STD_LOGIC_VECTOR (9 DOWNTO 0);			--	Toggle Switch[9:0]

		------------------------	7-SEG Display	------------------------
		hex0 	:		OUT	STD_LOGIC_VECTOR (6 DOWNTO 0);		--	Seven Segment Digit 0
		hex1 	:		OUT	STD_LOGIC_VECTOR (6 DOWNTO 0);		--	Seven Segment Digit 1
		hex2 	:		OUT	STD_LOGIC_VECTOR (6 DOWNTO 0);		--	Seven Segment Digit 2
		hex3 	:		OUT	STD_LOGIC_VECTOR (6 DOWNTO 0);		--	Seven Segment Digit 3

		----------------------------	LED		----------------------------
		ledg 	:		OUT	STD_LOGIC_VECTOR (7 DOWNTO 0);		--	LED Green[7:0]
		ledr 	:		OUT	STD_LOGIC_VECTOR (9 DOWNTO 0);		--	LED Red[9:0]

		------------------------	PS2		--------------------------------
		ps2_dat 	:		INOUT	STD_LOGIC;	--	PS2 Data
		ps2_clk	:		INOUT	STD_LOGIC	--	PS2 Clock
	);
END calculator;

ARCHITECTURE struct OF calculator IS

	SIGNAL clockhz, resetn 	: STD_LOGIC;
	SIGNAL key0 				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL lights, key_on	: STD_LOGIC_VECTOR(2 DOWNTO 0);

	-- Sinal utilizado para armazenar os possíveis
	-- valores de entrada do teclado PS2.
	SIGNAL calc_input : STD_LOGIC_VECTOR(4 DOWNTO 0);

	-- Sinal utilizado para armazenar o código BCD
	-- que será utilizado para apresentar os valores
	-- numéricos da calculadora nos displays de 7 segmentos
	SIGNAL bcd : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Sinal utilizado para armazenar o primeiro operando da
	-- calculadora
	SIGNAL first_number : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	-- Sinal utilizado para armazenar o segundo operando da
	-- calculadora
	SIGNAL second_number : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	-- Sinal utilizado para armazenar o operando de trailing da
	-- calculadora
	SIGNAL trailing_number : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	-- Sinal utilizado para armazenar o valor atual do display
	SIGNAL display_number : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	-- Sinal utilizado para armazenar o primeiro operador da
	-- FSM da calculadora
	SIGNAL operation1 : STD_LOGIC_VECTOR(4 DOWNTO 0);

	-- Sinal utilizado para armazenar o segundo operador da
	-- FSM da calculadora
	SIGNAL operation2 : STD_LOGIC_VECTOR(4 DOWNTO 0);

	-- Definição dos 8 possíveis estados da máquina de
	-- estados da calculadora.
	TYPE state_type IS (
		INITIAL,
		TRANSITION_FROM_INITIAL,
		TRANSITION,
		TRANSITION_FROM_TRANSITION,
		TRAILING,
		TRANSITION_FROM_TRAILING,
		EQUAL,
		ERROR
	);

	-- Sinais utilizados para armazenar o estado atual (state)
	-- e o próximo estado (next_state) da máquina de estados
	-- da calculadora.
	SIGNAL state, next_state : state_type;

	SIGNAL pwm_out : STD_LOGIC;

	SIGNAL duty : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Sinais utilizados para armazenar os valores
	-- dos quatro displays de 7 segmentos
	SIGNAL f0, f1, f2, f3 : STD_LOGIC_VECTOR(6 DOWNTO 0);

	-- Sinal utilizado para indicar a ocorrência de algum
	-- erro na ultima operação realizada pela calculadora.
	SIGNAL error_result : STD_LOGIC;

BEGIN

	resetn <= key(0);

	-- Definição do duty utilizado pelo gerador PWM.
	duty <= sw(7 DOWNTO 0);

	-- Instanciação do controlador PWM.
	pwm_controller: pwm PORT MAP(
		clk => clock_50,
		enable => '1',
		rstn => '1',
		duty => duty,
		pwm_out => pwm_out
	);

	-- Responsável pela conversão dos scancodes do teclado para um formato
	-- interno utilizado na calculadora.
	conv_input: scancode_to_calc_input PORT MAP(
		scancode => key0(7 DOWNTO 0),
		calc_input => calc_input
	);

	-- Processo responsável pelo controle de brilho dos displays de 7 segmentos.
	-- Também é responsável por mostrar a mensagem ERRO nos displays de 7 segmentos
	-- caso algum erro ocorra.
	pwm_dimmer: PROCESS(pwm_out)
	BEGIN
		IF (pwm_out = '1') THEN
			hex0 <= (OTHERS => '1');
			hex1 <= (OTHERS => '1');
			hex2 <= (OTHERS => '1');
			hex3 <= (OTHERS => '1');
		ELSE
			IF (error_result = '0') THEN
				hex0 <= f0;
				hex1 <= f1;
				hex2 <= f2;
				hex3 <= f3;
			ELSE
				hex0 <= "1000000"; -- E
				hex1 <= "0001000"; -- R
				hex2 <= "0001000"; -- R
				hex3 <= "0000110"; -- O
			END IF;
		END IF;
	END PROCESS;

	-- Processo responsável pela mudança para o estado seguinte da FSM.
	register_func: PROCESS(clock_24(0), resetn)
	BEGIN
		IF (resetn = '0') THEN
			state <= INITIAL;
		ELSIF (clock_24(0)'event and clock_24(0) = '1') THEN
			state <= next_state;
		END IF;
	END PROCESS;

	-- Processo responsável pela definição do próximo estado da FSM
	-- de acordo com os valores de entrada do teclado e o estado atual.
	next_state_func: PROCESS(calc_input, state)

	-- Variáveis temporárias utilizadas para armazenar os valores do primeiro
	-- operando (fn), segundo operando (sn) e operando de trailing (tn).
	VARIABLE fn, sn, tn : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	-- Variáveis utilizadas para armazenar um indicador de possível erro
	-- de acordo com os operandos e operadores possíveis.
	VARIABLE error_result_f_op1_s, error_result_s_op2_t, error_result_f_op1_s_op2_t  : STD_LOGIC;

	BEGIN
		IF (key_on(0)'event and key_on(0) = '1') THEN

			-- Inicializa os valores das variáveis temporárias com
			-- os valores atuais dos sinais correspondentes.
			fn := first_number;
			sn := second_number;
			tn := trailing_number;

			CASE state IS

				WHEN INITIAL =>
					fn := ZERO;
					operation1 <= SUM;
					sn := ZERO;
					operation2 <= SUM;
					tn := ZERO;
					error_result_f_op1_s := '0';
					error_result_s_op2_t := '0';
					error_result_f_op1_s_op2_t := '0';
					error_result <= '0';

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						fn := ZERO;
						fn := get_resulting_display(fn, calc_input(3 DOWNTO 0));
						next_state <= TRANSITION_FROM_INITIAL;
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						next_state <= INITIAL;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_operation(calc_input)) THEN
						-- pressionando qualquer tecla de operador (+,-,*/)
						fn := sn;
						operation1 <= calc_input;
						next_state <= TRANSITION;
					END IF;
					--------------------------------------------------------------


				WHEN TRANSITION_FROM_INITIAL =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						fn := get_resulting_display(fn, calc_input(3 DOWNTO 0));
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						IF (fn /= ZERO) THEN
							fn := ZERO;
						ELSE
							next_state <= INITIAL;
						END IF;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_operation(calc_input)) THEN
						-- caso a entrada seja qualquer operação:
						-- move para TRANSITION
						sn := fn; -- to verify
						operation1 <= calc_input;
						next_state <= TRANSITION;
					END IF;
					--------------------------------------------------------------


				WHEN TRANSITION =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						-- caso entrada seja qualquer número: move de volta para
						-- TRANSITION_FROM_TRANSITION
						sn := ZERO;
						sn := get_resulting_display(sn, calc_input(3 DOWNTO 0));
						next_state <= TRANSITION_FROM_TRANSITION;
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						fn := ZERO;
						next_state <= TRANSITION_FROM_INITIAL;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_operation(calc_input)) THEN
						-- caso a entrada seja qualquer operação:
						-- move de volta para TRANSITION
						operation1 <= calc_input;
						next_state <= TRANSITION;
					--------------------------------------------------------------
					END IF;

				WHEN TRANSITION_FROM_TRANSITION =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						sn := get_resulting_display(sn, calc_input(3 DOWNTO 0));
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						IF (sn /= ZERO) THEN
							sn := ZERO;
						ELSE
							next_state <= INITIAL;
						END IF;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_complex_operation(calc_input) AND is_simple_operation(operation1)) THEN
						operation2 <= calc_input;
						tn := sn;
						next_state <= TRAILING;
					ELSIF (is_simple_operation(calc_input) OR is_complex_operation(operation1)) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							operation1 <= calc_input;
							sn := fn;
							next_state <= TRANSITION;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					END IF;
					--------------------------------------------------------------


				WHEN TRAILING =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						tn := ZERO;
						tn := get_resulting_display(tn, calc_input(3 DOWNTO 0));
						next_state <= TRANSITION_FROM_TRAILING;
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN

						evaluate(sn, tn, operation2, sn, error_result_s_op2_t);
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s_op2_t);
						IF (error_result_f_op1_s_op2_t = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s_op2_t;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						tn := ZERO;
						next_state <= TRANSITION_FROM_TRAILING;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_simple_operation(calc_input)) THEN
						-- caso de operação simples (+,-): move de volta para TRANSITION
						evaluate(sn, tn, operation2, sn, error_result_s_op2_t);
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s_op2_t);
						IF (error_result_f_op1_s_op2_t = '0') THEN
							sn := fn;
							operation1 <= calc_input;
							next_state <= TRANSITION;
						ELSE
							error_result <= error_result_f_op1_s_op2_t;
							next_state <= ERROR;
						END IF;
					ELSIF (is_complex_operation(calc_input)) THEN
						-- caso de operação complexa (*,/): permanece em TRAILING
						operation2 <= calc_input;
					END IF;
					--------------------------------------------------------------


				WHEN TRANSITION_FROM_TRAILING =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN
						tn := get_resulting_display(tn, calc_input(3 DOWNTO 0));
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(sn, tn, operation2, sn, error_result_s_op2_t);
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s_op2_t);
						IF (error_result_f_op1_s_op2_t = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s_op2_t;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						IF (tn /= ZERO) THEN
							tn := ZERO;
						ELSE
							next_state <= INITIAL;
						END IF;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_simple_operation(calc_input)) THEN
						evaluate(sn, tn, operation2, sn, error_result_s_op2_t);
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s_op2_t);
						-- caso de operação simples (+,-): move de volta para TRANSITION
						IF (error_result_f_op1_s_op2_t = '0') THEN
							operation1 <= calc_input;
							sn := fn;
							next_state <= TRANSITION;
						ELSE
							error_result <= error_result_f_op1_s_op2_t;
							next_state <= ERROR;
						END IF;

					ELSIF (is_complex_operation(calc_input)) THEN
						-- caso de operação complexa (*,/): permanece em TRAILING
						evaluate(sn, tn, operation2, sn, error_result_s_op2_t);
						IF (error_result_s_op2_t = '0') THEN
						tn := sn;
							operation2 <= calc_input;
							next_state <= TRAILING;
						ELSE
							error_result <= error_result_s_op2_t;
							next_state <= ERROR;
						END IF;

					END IF;
					--------------------------------------------------------------


				WHEN EQUAL =>

					------------------ lida com entrada numérica -----------------
					IF (is_number(calc_input)) THEN -- any number
						fn := ZERO;
						fn := get_resulting_display(fn, calc_input(3 DOWNTO 0));
						next_state <= TRANSITION_FROM_INITIAL;
					--------------------------------------------------------------

					--------------- lida com a tecla enter (igual) ---------------
					ELSIF (calc_input = ENTER) THEN
						evaluate(fn, sn, operation1, fn, error_result_f_op1_s);
						IF (error_result_f_op1_s = '0') THEN
							next_state <= EQUAL;
						ELSE
							error_result <= error_result_f_op1_s;
							next_state <= ERROR;
						END IF;
					--------------------------------------------------------------

					---------------- lida com a tecla esc (reset) ----------------
					ELSIF (calc_input = RES) THEN
						fn := ZERO;
						next_state <= TRANSITION_FROM_INITIAL;
					--------------------------------------------------------------

					---------------- lida com entrada de operador ----------------
					ELSIF (is_operation(calc_input)) THEN -- any operation
						operation1 <= calc_input;
						sn := fn;
						next_state <= TRANSITION;
					END IF;
					--------------------------------------------------------------


				WHEN ERROR =>
					---------------- lida com a tecla esc (reset) ----------------
					IF (calc_input = RES) THEN
						next_state <= INITIAL;
						error_result <= '0';
						fn := (OTHERS => '0');
					END IF;
					--------------------------------------------------------------

			END CASE;

			-- Atualiza os valores dos sinais com suas respectivas variáveis.
			first_number <= fn;
			second_number <= sn;
			trailing_number <= tn;

		END IF;
	END PROCESS;

	-- Processo que define o valor de saída da máquina de estados da calculadora
	-- que será apresentado nos quatro displays de 7 segmentos de acordo com
	-- o estado atual.
	output_func: PROCESS(calc_input, state)
	BEGIN
		CASE state IS

			WHEN INITIAL =>
				display_number <= first_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(7) <= '1';

			WHEN TRANSITION_FROM_INITIAL =>
				display_number <= first_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(6) <= '1';

			WHEN TRANSITION =>
				display_number <= first_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(5) <= '1';

			WHEN TRANSITION_FROM_TRANSITION =>
				display_number <= second_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(4) <= '1';

			WHEN TRAILING =>
				display_number <= second_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(3) <= '1';

			WHEN TRANSITION_FROM_TRAILING =>
				display_number <= trailing_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(2) <= '1';

			WHEN EQUAL =>
				display_number <= first_number;
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(1) <= '1';

			WHEN ERROR =>
				ledr(7 DOWNTO 0) <= (OTHERS => '0');
				ledr(0) <= '1';

		END CASE;
	END PROCESS;

	-- Instanciação da entidade que faz a conversão de um número binário para
	-- codificação binária decimal (BCD) utilizando o algoritmo double dabble.
	bin2bcd: binary_to_bcd PORT MAP(
		binary => display_number,
		bcd_uni => bcd(3 DOWNTO 0),
		bcd_ten => bcd(7 DOWNTO 4),
		bcd_hun => bcd(11 DOWNTO 8),
		bcd_tho => bcd(15 DOWNTO 12)
	);

	-- Instanciação da entidade responsável pela conversão de um código binário
	-- para representação no primeiro display de 7 segmentos.
	hexseg0: conv_7seg PORT MAP(
		bcd(3 DOWNTO 0), f0
	);

	-- Instanciação da entidade responsável pela conversão de um código binário
	-- para representação no segundo display de 7 segmentos.
	hexseg1: conv_7seg PORT MAP(
		bcd(7 DOWNTO 4), f1
	);

	-- Instanciação da entidade responsável pela conversão de um código binário
	-- para representação no terceiro display de 7 segmentos.
	hexseg2: conv_7seg PORT MAP(
		bcd(11 DOWNTO 8), f2
	);

	-- Instanciação da entidade responsável pela conversão de um código binário
	-- para representação no quarto display de 7 segmentos.
	hexseg3: conv_7seg PORT MAP(
		bcd(15 DOWNTO 12), f3
	);

	-- Instanciação da entidade que interpreta e transmite os pacotes com os
	-- comandos utilizados pelo teclado.
	kbd_ctrl : kbdex_ctrl generic map(24000) PORT MAP(
		ps2_dat, ps2_clk, clock_24(0), key(1), resetn, lights(1) & lights(2) & lights(0),
		key_on, key_code(15 DOWNTO 0) => key0
	);

	-- Saída do LEDR9 indicando se o número nos displays de 7 segmentos é
	-- negativo (ligado) ou não (desligado).
	ledr(9) <= '1' WHEN display_number(N-1) = '1' ELSE
				  '0';
END struct;
