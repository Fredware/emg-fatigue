#define SAMPLING_PERIOD 1000 // microseconds = 1kHz sampling freq
#define SERIAL_PLOTTER_ENABLED 0

int musclePin[] = {A1};   // Arduino input locations (A2 and A1 are the inputs for the EMG shield)

char print_buff[5];    // allocate space for reading voltages

void setup()
{
  Serial.begin( 256000); // this number is the Baudrate, and it must match the serial setup in MATLAB
  delay( 10);          // evoke a delay to let the serial setup
}

void loop()
{
  unsigned long start_time = micros();  //start timer
  
  // read voltages
  // string must match in matlab code
  // use one %d per channel separated by a space
  sprintf( print_buff,
           "%d",           
           analogRead( musclePin[0])
  );
  if (SERIAL_PLOTTER_ENABLED)
  {
    Serial.print(0);
    Serial.print("\t");
    Serial.print(1024);
    Serial.print("\t");
  }
  Serial.println(print_buff);        // write the voltages to serial
  
  long stop_time = micros() - start_time; // determine how long it took to write
  
  if( stop_time < SAMPLING_PERIOD) // force a maximum sampling rate of 1 kHz
  {
    delayMicroseconds( SAMPLING_PERIOD - stop_time);
  }
}
