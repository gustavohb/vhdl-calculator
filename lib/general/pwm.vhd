LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Entidade responsável pela geração do sinal PWM.
-- Entradas: 1. sinal de clock
--           2. sinal que indica se está o PWM habilitado.
--           3. sinal de reset ativo em nível baixo.
--           4. um vetor de 8 bits do tipo STD_LOGIC_VECTOR utilizado para o
--              calculo do duty-cycle
-- Saída: um bit do tipo STD_LOGIC que representa se o sinal PWM está ativo ou não.
ENTITY pwm IS
	PORT (clk, enable, rstn : IN STD_LOGIC;
			duty : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			pwm_out : OUT STD_LOGIC);
END pwm;

ARCHITECTURE pwm_arch OF pwm IS

SIGNAL count : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	PROCESS(rstn, clk, enable) IS
	BEGIN
		IF (rstn = '0') THEN
			count <= "00000000";
			pwm_out <= '0';
		ELSIF (enable = '1') THEN
			IF (clk'EVENT AND clk = '1') THEN
				count <= count + 1;
				IF (count <= duty) THEN
					pwm_out <= '1';
				ELSIF (count = "11111111") THEN
					count <= "00000000";
				ELSE
					pwm_out <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
END pwm_arch;
