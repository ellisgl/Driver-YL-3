const int clock = 7; //SCK
const int latch = 5; //RCK 
const int data  = 6; //DIO
char str[7][8] = 
{
  "   HELLO",
  "  HELLO ",
  " HELLO  ",
  "HELLO   ",
  " HELLO  ",
  "  HELLO "
};

char schr;

byte value[]    =
{ 
  B11000000, // 0/O 
  B11111001, // 1   
  B10100100, // 2  
  B10110000, // 3
  B10011001, // 4
  B10010010, // 5/S/s
  B10000010, // 6
  B11111000, // 7
  B10000000, // 8
  B10010000, // 9
  B10001000, // A
  B10100000, // a
  B10000011, // B/b
  B11000110, // C
  B10100111, // c
  B10100001, // D/d
  B10000110, // E
  B10000100, // e
  B10001110, // F/f
  B10010000, // G/g
  B10001001, // H
  B10001011, // h
  B11110001, // J
  B11110011, // j
  B11000111, // L
  B11100111, // l
  B10101011, // N/n
  B10101011, // o
  B10001100, // P/p
  B01000000, // Q
  B00100011, // q
  B11001110, // R
  B10101111, // r
  B10000111, // T
  B11000001, // U
  B11100011, // u
  B10000111, // °
  B01111111, // .
  B11111111 // display nothing
};

byte digit[]    =
{
  B00000001, // left segment
  B00000010,
  B00000100,
  B00001000,
  B00010000,
  B00100000,
  B01000000,
  B10000000 // right segment
}; 

byte chr                  = B11111111;
int x                     = 0;
const long interval       = 1000;
unsigned long startTime   = millis();
unsigned long currentTime = startTime;  


void setup()
{
  Serial.begin(9600);
  pinMode(clock, OUTPUT);
  pinMode(latch, OUTPUT);
  pinMode(data, OUTPUT);
}



void loop()
{
  
  if (currentTime - startTime < interval)
  {
    currentTime = millis();
    
    for(int y = 0; y < 8; y++)
    {
      switch(str[x][y])
      {
        case '0':
        case 'O':
          chr = value[0];
        break;

        case '1':
          chr = value[1];
        break;

        case '2':
          chr = value[2];
        break;

        case '3':
          chr = value[3];
        break;

        case '4':
          chr = value[4];
        break;

        case '5':
        case 'S':
        case 's':
          chr = value[5];
        break;

        case '6':
          chr = value[6];
        break;

        case '7':
          chr = value[7];
        break;

        case '8':
          chr = value[8];
        break;

        case '9':
          chr = value[9];
        break;

        case 'A':
          chr = value[10];
        break;

        case 'a':
          chr = value[11];
        break;

        case 'B':
        case 'b':
          chr = value[12];
        break;

        case 'C':
          chr = value[13];
        break;

        case 'c':
          chr = value[14];
        break;

        case 'D':
        case 'd':
          chr = value[15];
        break;

        case 'E':
          chr = value[16];
        break;

        case 'e':
          chr = value[17];
        break;

        case 'F':
        case 'f':
          chr = value[18];
        break;
        case 'G':
        case 'g':
          chr = value[19];
        break;

        case 'H':
          chr = value[20];
        break;

        case 'h':
          chr = value[21];
        break;

        case 'J':
          chr = value[22];
        break;

        case 'j':
          chr = value[23];
        break;

        case 'L':
          chr = value[24];
        break;

        case 'l':
          chr = value[25];
        break;

        case 'N':
        case 'n':
          chr = value[26];
        break;

        case 'o':
          chr = value[27];
        break;

        case 'P':
        case 'p':
          chr = value[28];
        break;

        case 'Q':
          chr = value[29];
        break;

        case 'q':
          chr = value[30];
        break;

        case 'R':
          chr = value[31];
        break;

        case 'r':
          chr = value[32];
        break;

        case 'T':
        case 't':
          chr = value[33];
        break;

        case 'U':
          chr = value[34];
        break;

        case 'u':
          chr = value[35];
        break;

        case '°':
          chr = value[36];
        break;

        case '.':
          chr = value[37];
        break;

        default:
          chr = value[38];
      }

      digitalWrite(latch,LOW);
      shiftOut(data, clock, MSBFIRST, digit[y]); // select all segments
      shiftOut(data, clock, MSBFIRST, chr); // display char
      digitalWrite(latch,HIGH);
    }
  }
  else
  {
    x++;
 
    if(x == 6)
    {
      x = 0;
    }
    
    startTime   = millis();
    currentTime = startTime;  
  }
}
