#include <Servo.h>
#include <IRremote.h>
#include "Jaguar.h"

#define ledPin 6
#define reedPin 2

Jaguar jag;
IRrecv irrecv(8);
decode_results results;

int value = 0;
boolean isForward = true;

void setup() {
  irrecv.enableIRIn();

  pinMode(reedPin, INPUT_PULLUP);
  
  jag.attach(5);
  jag.move(0);
  
  Serial.begin(9600);
  Serial.println("Ready.");
}

void loop() {

  if (digitalRead(2) == LOW) { // MAY CHANGE
    if (irrecv.decode(&results)) {
      //Serial.println(results.value, HEX);
      translateIR();
      irrecv.resume(); // Receive the next value
    } else if (Serial.available() > 0) {
      value = Serial.read();
      if (value == 101) {
        isForward = false;
        Serial.println("BACKWARD");
      } else if (value == 102) {
        isForward = true;
        Serial.println("FORWARD");
      }
    }
  
    if (isForward == false && value >= 0) {
      value = -value;
    }
  
    value = (value<=-100)? -100 : ((value>=100)? 100 : value);
    Serial.println(value);
    
    analogWrite(ledPin, abs(map(value, -100, 100, -255, 255)));
    jag.move(value);
  } else {
    jag.move(0);
    analogWrite(ledPin, 0);
    value = 0;
  }
}

void translateIR() {
  switch(results.value) {
  case 0xFF629D: Serial.println(" FORWARD"); value += 5; break;
  case 0xFF22DD: Serial.println(" LEFT");    break;
  case 0xFF02FD: Serial.println(" -OK-");    value = 0; break;
  case 0xFFC23D: Serial.println(" RIGHT");   break;
  case 0xFFA857: Serial.println(" REVERSE"); value-= 5; break;
  case 0xFF6897: Serial.println(" 1");  value = 25;   break;
  case 0xFF9867: Serial.println(" 2");  value = 50;   break;
  case 0xFFB04F: Serial.println(" 3");  value = 75;   break;
  case 0xFF30CF: Serial.println(" 4");  value = 100;   break;
  case 0xFF18E7: Serial.println(" 5");  value = -25;   break;
  case 0xFF7A85: Serial.println(" 6");  value = -50;   break;
  case 0xFF10EF: Serial.println(" 7");  value = -75;   break;
  case 0xFF38C7: Serial.println(" 8");  value = -100;   break;
  case 0xFF5AA5: Serial.println(" 9");    break;
  case 0xFF42BD: Serial.println(" *");    break;
  case 0xFF4AB5: Serial.println(" 0");  value = 0;  break;
  case 0xFF52AD: Serial.println(" #");    break;
  case 0xFFFFFFFF: Serial.println(" REPEAT");break;  
  default: Serial.println("other button");
  } 
}
