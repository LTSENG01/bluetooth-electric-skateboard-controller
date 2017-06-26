#ifndef JAGUAR_H
#define JAGUAR_H

#ifndef SERVO_H
//#error "Must #include <Servo.h> in sketch before " __FILE__
#endif

class Jaguar {
public:
    Jaguar() = default;
    Jaguar(uint8_t inpin) {
        pin = inpin;
    }

    attach() {
        jaginput.attach(pin);
        initialized = true;
    }
    void attach(uint8_t inpin) {
        pin = inpin;
        attach();
    }

    unsigned int move(int speed) {
        if (!initialized) {
            attach(pin);
        }
        // Make sure speed is between -100 and 100
        speed = (speed<=-100)? -100 : ((speed>=100)? 100 : speed);
        // Scale {-100,100} to {670, 2330}
        unsigned int siglen = map(speed, -100, 100, 670, 2330);
        jaginput.writeMicroseconds(siglen);
        return siglen;
    }
private:
    uint8_t pin;
    bool initialized;
    Servo jaginput;
};

#endif // JAGUAR_H
