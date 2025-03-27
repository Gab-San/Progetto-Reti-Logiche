library ieee;
use ieee.std_logic_1164.all;

-- Interfaccia con la memoria
Entity project_reti_logiche is
   Port(
        i_clk: IN std_logic;     
        i_rst: IN std_logic;
        i_start: IN std_logic;
        
        i_add: IN std_logic_vector(15 downto 0);
        i_k: IN std_logic_vector(9 downto 0);
        
        o_done: OUT std_logic;
        
        o_mem_addr: OUT std_logic_vector(15 downto 0);
        
        i_mem_data: IN std_logic_vector(7 downto 0);
        o_mem_data: OUT std_logic_vector(7 downto 0);
        -- Write Enable signal: 0 read - 1 write
        o_mem_we: OUT std_logic;
        -- Enable signal
        o_mem_en: OUT std_logic
    );
END project_reti_logiche;

Architecture FSM of project_reti_logiche is
    component WordManager is
        Port(
            clock, reset: in STD_LOGIC;
            first_read, word_load: in STD_LOGIC;
            input_data: in STD_LOGIC_VECTOR(7 downto 0);
            sig_data_eq_zero: out STD_LOGIC;
            output_word: out STD_LOGIC_VECTOR(7 downto 0)
        );
    END component WordManager;
    
    component CredibilityTracker is
        Port(
            clock, reset: in STD_LOGIC;
            credibility_reg_load: in STD_LOGIC;
            first_read, sig_data_eq_zero: in STD_LOGIC;
            -- This is extended to 8 bit in order to match with o_mem_data
            credibility_output: out STD_LOGIC_VECTOR(7 downto 0)
        );
    END component CredibilityTracker;
    
    component AddressTracker is
        Port(
            clock, reset: STD_LOGIC;
            starting_addr: in STD_LOGIC_VECTOR(15 downto 0);
            -- logic and control signals
            addr_count_init, addr_load: in STD_LOGIC;
            next_addr: out STD_LOGIC_VECTOR(15 downto 0)
        );
    END component AddressTracker;
    
    component SequenceTracker is
        Port(
            clock, reset: in STD_LOGIC;
            seq_count_load, seq_count_init: in STD_LOGIC;
            sequence_length: in STD_LOGIC_VECTOR(9 downto 0);
            sig_end_seq: out STD_LOGIC
        );
    END component SequenceTracker;
    
        -- --- Control signals of FSM -----
    signal first_read_in, first_read_out, first_read_load: STD_LOGIC;
    -- signals that control i_mem_data and o_mem_data
    signal sig_data_eq_zero, output_data_selector: STD_LOGIC;
    -- signals referring strictly to WordManager and CredibilityTracker
    signal w_load, cred_reg_load: STD_LOGIC;
    signal w_out, cred_out: STD_LOGIC_VECTOR(7 downto 0);
    -- Address Tracker signals
    signal addr_count_init, addr_load: STD_LOGIC;
    -- Sequence Tracker signals
    signal seq_count_load, seq_count_init, sig_end_seq: STD_LOGIC;
    
    -- FSM declaration
    -- RST_S: Reset State
    -- READ_1: read init - READ_2: eff read
    -- WW: Write Word when the input is 0
    -- WC: Write Credibility
    -- ADVMEM: ADVance to next MEMory address to restart reading
    -- ADV_NEXT_READ: ADVance to NEXT READ address
    -- DONE
    type STATE_TYPE is (RST_S, READ_1, READ_2, WW, WC, ADVMEM, ADV_NEXT_READ, DONE);
    signal current_state, next_state: STATE_TYPE;
BEGIN
    -- This flip flop lets me set a signal to notify when the first read of the computation
    -- occurs. Used especially as a workaround to the "0 as starting value of the computation" edge case.
    first_read_reg: process(i_clk, i_rst)
    BEGIN
        if i_rst = '1' then
            first_read_out <= '0';
        elsif rising_edge(i_clk) then
            if first_read_load = '1' then
                first_read_out <= first_read_in;
            END if;
        END if;
    END process first_read_reg;
    
    -- Path from i_mem_data to o_mem_data
    WordMan: WordManager
        Port map(clock => i_clk, reset => i_rst, first_read => first_read_out, word_load => w_load,
                    input_data => i_mem_data, sig_data_eq_zero => sig_data_eq_zero, output_word => w_out);
    
    CredTrack: CredibilityTracker
        Port map(clock => i_clk, reset => i_rst, credibility_reg_load => cred_reg_load, 
             first_read => first_read_out, sig_data_eq_zero => sig_data_eq_zero, credibility_output => cred_out);
    
    o_mem_data <=   cred_out when output_data_selector = '1' else
                    w_out;
    -- Path from i_add to o_mem_addr
    AddTrack: AddressTracker
        Port map(clock => i_clk, reset => i_rst, starting_addr => i_add, 
                    addr_count_init => addr_count_init, addr_load => addr_load, next_addr => o_mem_addr);
    -- Path from i_k to sig_end_seq
    SeqTrack: SequenceTracker
        Port map(clock => i_clk, reset => i_rst, sequence_length => i_k, 
                    seq_count_load => seq_count_load, seq_count_init => seq_count_init,
                        sig_end_seq => sig_end_seq);
    
    -- ---- FSM Implementation ------
    state_reg: process(i_clk, i_rst)
    BEGIN
        if i_rst = '1' then
            current_state <= RST_S;
        elsif i_clk'event and i_clk = '1' then
            current_state <= next_state;
        END if;
    END process state_reg;
    
    def_next_state: process(current_state, i_start, sig_end_seq, sig_data_eq_zero)
    BEGIN
        case current_state is
            when RST_S =>
                if i_start = '0' then
                    next_state <= RST_S;
                else
                    next_state <= READ_1;
                END if;
            when READ_1 =>
                -- If i_k = 0 after the first read the computation is already done
                if sig_end_seq = '0' then
                    next_state <= READ_2;
                else
                    next_state <= DONE;
                END if;
            when READ_2 =>
                -- if the current input is 0 than the last 
                -- read word must be written into the byte
                if sig_data_eq_zero = '1' then
                    next_state <= WW;
                -- otherwise it can jump to write the credibility
                else
                    next_state <= ADVMEM;
                END if;
            when WW =>
                -- Write the current cred
                next_state <= WC;
            when ADVMEM =>
                next_state <= WC;
            when WC =>
                -- There's still a word to be read
                if sig_end_seq = '0' then
                    next_state <= ADV_NEXT_READ;
                else
                    next_state <= DONE;
                END if;
            when ADV_NEXT_READ =>
                next_state <= READ_1;
            when DONE =>
                if i_start = '0' then
                    next_state <= RST_S;
                else
                    next_state <= DONE;
                END if;
        END case;
    END process def_next_state;
    
    signal_config: process(current_state)
    BEGIN
        o_done <= '0';
        o_mem_we <= '0';
        output_data_selector <= '-';
        -- In a normal circumstance the following registers won't be overwritten
        addr_count_init <= '-';
        addr_load <= '0';
        
        seq_count_init <= '-';
        seq_count_load <= '0';
        
        first_read_in <= '-';
        first_read_load <= '0';
        
        w_load <= '0';
        cred_reg_load <= '0';
        
        -- In each state will be highlighted important signals only
        case current_state is
            when RST_S =>
                o_done <= '0';
                o_mem_en <= '0';
                -- Initializing counter...
                addr_count_init <= '1';
                addr_load <= '1';
                --Initializing counter... #read word = 0
                seq_count_init <= '1';
                seq_count_load <= '1';
                -- Waiting for a new computation, meaning no word was read
                first_read_in <= '1';
                first_read_load <= '1';
            when READ_1 =>
                -- Accessing for read
                o_mem_en <= '1';
                o_mem_we <= '0';
                w_load <= '0';
            when READ_2 =>
                o_mem_en <= '1';
                o_mem_we <= '0';
                -- #read word + 1 <--> #total words - 1
                seq_count_init <= '0';
                seq_count_load <= '1';
                -- Reading a word brings down this signal
                first_read_in <= '0';
                first_read_load <= '1';
                -- In this state all the signals need to select the correct 
                -- credibility value are set
                w_load <= '1';
                cred_reg_load <= '1';
            when WW =>
                -- Accessing for writing...
                o_mem_en <= '1';
                o_mem_we <= '1';
                -- Accessing ADD+1 for next clock
                addr_count_init <= '0';
                addr_load <= '1';
                -- Selecting the last read word
                output_data_selector <= '0';
                cred_reg_load <= '0';
            when ADVMEM =>
                  -- Accessing for writing...
                  o_mem_en <= '0';
                  -- Accessing ADD+1
                  addr_count_init <= '0';
                  addr_load <= '1';
                  w_load <= '0';
                  cred_reg_load <= '0';
            when WC =>
                -- Accessing for writing...
                o_mem_en <= '1';
                o_mem_we <= '1';
                -- Selecting the credibility value
                output_data_selector <= '1';
                
                cred_reg_load <= '0';
            when ADV_NEXT_READ =>
                o_mem_en <= '0';
                -- Advancing to (ADD + 1) + 1 to start the new read
                addr_count_init <= '0';
                addr_load <= '1';
                w_load <= '0';
                cred_reg_load <= '0';
            when DONE =>
                o_done <= '1';
                o_mem_en <= '0';
        END case;
    END process signal_config;
END FSM;

-- ------------------------------------------------------------------------------------------------------------

-- Defining a component that functions as a counter. 

-- It stores the next number in the sequence when the load signal is high.
-- It was thought as so due to the starting address and the sequence number signals being constant:
-- instead of storing and manipulating directly that value, an operation of addition or subtraction 
-- occurs everytime between these constant signals and the counter, giving exactly the same value as
-- if directly manipulated.

-- This approach follows the modularity principle, instead of having each signal treated "ad hoc".

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity Counter is
    Generic(N : INTEGER := 10);
    Port(
        clock, reset: in STD_LOGIC;
        -- logic and control signals
        counter_init, counter_load: in STD_LOGIC;
        counter_output: out STD_LOGIC_VECTOR(N-1 downto 0)
    );
END Counter;

Architecture CountByOne of Counter is
    signal next_value, current_value : STD_LOGIC_VECTOR(N-1 downto 0);
    constant const_zero: STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
BEGIN
    
    -- This is a mutex that makes it possible to reinitialize the counter when in the
    -- reset state, even though no reset signal was sent in order to start counting from 0
    next_value <=   const_zero when counter_init = '1' else
                    STD_LOGIC_VECTOR(SIGNED(current_value) + 1) when counter_init = '0';
    
    -- This process defines a registry that stores the counter value when 
    -- the "load" signal is high
    counter_registration: process(clock, reset)
    BEGIN
        if reset = '1' then
            -- When reset the value in output from the counter should be zero
            -- since the counting cycle has yet to start
            current_value <= (others => '0');
        elsif clock'event and clock = '1' then
            -- The (counting) signal is registered when
            -- counter_load is high on the rising edge of the clock
            if counter_load = '1' then
                current_value <= next_value;
            END if;
        END if;
    END process counter_registration;
    
    -- The output will be the current_value stored in the N bit registry
    counter_output <= current_value;
END CountByOne;

-- Note: The architecture could be changed from CountByOne to CountByN by simply adding another input signal
-- which would be the constant value to add at each iteration. Sticking with the CountByOne architecture
-- was a matter of engineering simplicity for this project.

-- ------------------------------------------------------------------------------------------------------------

-- Defining a component that is responsible for tracking the transformation of the input address 
-- into the sequence of output addresses reached throughout the sequence:
-- a "starting address" is a constant signal to which is added an offset given by a Counter component,
-- the result is the output address

-- Size of address signal is 16 bits for this project
-- (for more info see also Counter doc)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity AddressTracker is
    Port(
        clock, reset: STD_LOGIC;
        starting_addr: in STD_LOGIC_VECTOR(15 downto 0);
        -- logic and control signals
        addr_count_init, addr_load: in STD_LOGIC;
        next_addr: out STD_LOGIC_VECTOR(15 downto 0)
    );
END AddressTracker;

Architecture AddressCounter of AddressTracker is
    component Counter is
        Generic(N : INTEGER := 10);
        Port(
            clock, reset: in STD_LOGIC;
            -- logic and control signals
            counter_init, counter_load: in STD_LOGIC;
            counter_output: out STD_LOGIC_VECTOR(N-1 downto 0)
        );
    END component Counter;
    
    signal offset_address: STD_LOGIC_VECTOR(15 downto 0);
BEGIN
    AddrCount: Counter
        Generic map(N => 16)
        Port map(clock => clock, reset => reset, counter_init => addr_count_init,
                    counter_load => addr_load, counter_output => offset_address);
    
    next_addr <= STD_LOGIC_VECTOR(SIGNED(starting_addr) + SIGNED(offset_address));
END AddressCounter;

-- ------------------------------------------------------------------------------------------------------------

-- Defining a component to track the number of reads and signal the end of the reads sequence.
-- The sequence length is defined by a constant signal. To determine the number of remaining reads
-- this component subtracts the current number of reads ("read_count" signal) and then checks if
-- it has reached 0; when this event occurs the output signal of this component rises to 1, indicating
-- that the sequence has been read and there is no need to further proceed with computation.

-- Size of sequence length signal is 10 bits for this project
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity SequenceTracker is
    Port(
        clock, reset: in STD_LOGIC;
        seq_count_load, seq_count_init: in STD_LOGIC;
        sequence_length: in STD_LOGIC_VECTOR(9 downto 0);
        sig_end_seq: out STD_LOGIC
    );
END SequenceTracker;

Architecture SequenceCounter of SequenceTracker is
    component Counter is
        Generic(N : INTEGER := 10);
        Port(
            clock, reset: in STD_LOGIC;
            -- logic and control signals
            counter_init, counter_load: in STD_LOGIC;
            counter_output: out STD_LOGIC_VECTOR(N-1 downto 0)
        );
    END component Counter;
    
    signal read_count: STD_LOGIC_VECTOR(9 downto 0);
    -- This signal is used for better debugging readability
    signal read_diff: SIGNED(9 downto 0);

BEGIN
    SeqCount: Counter
        Generic map(N => 10)
        Port map(clock => clock, reset => reset, counter_init => seq_count_init,
                    counter_load => seq_count_load, counter_output => read_count); 
    read_diff <= SIGNED(sequence_length) - SIGNED(read_count);
    -- This signal will be brought to high when the whole sequence has been computed
    sig_end_seq <=  '1' when read_diff = 0 else
                    '0';
                    
END SequenceCounter;


-- ------------------------------------------------------------------------------------------------------------

-- Defining a module to manage credibility. 
-- This module requires to consider few edge cases that make it not possible to implement with a constant
-- signal that operates along a counter.
-- It is composed of a 2 pin selector multiplexer that controls the credibility value based on 
-- two signals "first_read" and "sig_data_eq_zero".
-- The first one controls whether the cycle of computation has just started, the second one is a signal 
-- that is high when the input data read is the value of 0.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity CredibilityTracker is
    Port(
        clock, reset: in STD_LOGIC;
        credibility_reg_load: in STD_LOGIC;
        first_read, sig_data_eq_zero: in STD_LOGIC;
        -- This is extended to 8 bit in order to match with o_mem_data
        credibility_output: out STD_LOGIC_VECTOR(7 downto 0)
    );
END CredibilityTracker;

Architecture CredibilityCounter of CredibilityTracker is
    signal next_value, current_credibility: STD_LOGIC_VECTOR(5 downto 0);
    signal mutex_ctrl: STD_LOGIC_VECTOR(1 downto 0);
    constant const_zero : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    constant const_31: STD_LOGIC_VECTOR(5 downto 0) := (5 => '0', others => '1');
BEGIN
    -- This signal combines the signals in order to implements a 2 pin selector mutex
    mutex_ctrl(1) <= sig_data_eq_zero;
    mutex_ctrl(0) <= first_read;
                    -- It's the first time reading an input and it is 0
    next_value <=   const_zero when mutex_ctrl = "11" else 
                    -- It's not the first time reading an input but it's reading 0
                    STD_LOGIC_VECTOR(SIGNED(current_credibility) - 1) when mutex_ctrl = "10" else
                    -- It's not reading 0 as input
                    const_31;
    
    credibility_reg: process(clock, reset)
    BEGIN
        if reset = '1' then
            current_credibility <= (others => '0');
        elsif clock'event and clock = '1' then
            -- The credibility is stored iff it is >= 0. If next_value[5] = '1' it means
            -- that the number is negative, i.e. the difference between the current credibility value
            -- and 1 is lower than 0, hence it would cross 0. The last stored number is 0.
            if credibility_reg_load = '1' and not next_value(5) = '1' then
                current_credibility <= next_value;
            END if;
        END if;
    END process credibility_reg;
    -- Adding 6th and 7th bit
    credibility_output <= "00" & current_credibility;
END CredibilityCounter;

-- ------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

Entity WordManager is
    Port(
        clock, reset: in STD_LOGIC;
        first_read, word_load: in STD_LOGIC;
        input_data: in STD_LOGIC_VECTOR(7 downto 0);
        sig_data_eq_zero: out STD_LOGIC;
        output_word: out STD_LOGIC_VECTOR(7 downto 0)
    );
END WordManager;

Architecture WordController of WordManager is
    signal data_equal_zero, effective_load: STD_LOGIC;
BEGIN
    data_equal_zero   <=   '1' when input_data = "00000000" else
                           '0';
                            
    sig_data_eq_zero <= data_equal_zero;
                    -- In order to force a zero if read as the first number of the computation
    effective_load <=   data_equal_zero when (data_equal_zero and first_read) = '1' else
                    -- Stores a number if != 0
                        word_load and not data_equal_zero;
    word_reg: process(clock, reset)
    BEGIN
        if reset = '1' then
            output_word <= (others => '0');
        elsif rising_edge(clock) then
            if effective_load = '1' then
                output_word <= input_data;
            END if;
        END if;
    END process word_reg;
END WordController;

