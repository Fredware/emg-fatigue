#define SAMPLING_PERIOD 1000 // microseconds = 1kHz sampling freq

int musclePin[] = {A2, A1};   // Arduino input locations (A2 and A1 are the inputs for the EMG shield)

char print_buff[10];    // allocate space for reading voltages

void setup()
{
  Serial.begin( 9600); // this number is the Baudrate, and it must match the serial setup in MATLAB
  delay( 5000);          // evoke a delay to let the serial setup
}

void loop()
{
  long start_time = micros();  //start timer
  
  sprintf( print_buff,"%d %d",          // read voltages
           analogRead( musclePin[1]), 
           analogRead( musclePin[0])
  );

  Serial.println(print_buff);        // write the voltages to serial
  
  long stop_time = micros() - start_time; // determine how long it took to write
  
  if( stop_time < SAMPLING_PERIOD) // force a maximum sampling rate of 1 kHz
  {
    delayMicroseconds( SAMPLING_PERIOD - stop_time);
  }
}
