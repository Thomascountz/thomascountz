---
title: Arduino Tone for ESP32
Author: Thomas Countz
layout: post
tags: ["hardware", "esp32", "arduino", "firmware"]
---

Arduino has a built-in [`tone()`](https://www.arduino.cc/reference/en/language/functions/advanced-io/tone/) library which allows you to send a PWM `frequency` at 50% duty cycle to a specific `pin` in order to generate a tone on a piezoelectric buzzer with an optional `duration`.

```c
tone(pin, frequency)
tone(pin, frequency, duration)
```

This functionality is [famously](https://github.com/espressif/arduino-esp32/issues/980) [unavailable](https://github.com/espressif/arduino-esp32/issues/1720) in Espressif's [arduino-esp32](https://github.com/espressif/arduino-esp32) library and members of the community have found various [work-arounds](https://github.com/lbernstone/Tone) such as using the native [LED Control](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/ledc.html) functions to generate PWM signals.

However, looking more closely at [arduino-esp32](https://github.com/espressif/arduino-esp32) library, not only has Espressif provided a clean API for generating tones, they've provided an interface for generating specific PWM frequencies for specific notes on the chromatic scale in different octaves.

```c
double ledcWriteNote(uint8_t chan, note_t note, uint8_t octave){
  const uint16_t noteFrequencyBase[12] = {
  //   C        C#       D        Eb       E        F       F#        G       G#        A       Bb        B
      4186,    4435,    4699,    4978,    5274,    5588,    5920,    6272,    6645,    7040,    7459,    7902
  };

  if(octave > 8 || note >= NOTE_MAX){
      return 0;
  }
  double noteFreq =  (double)noteFrequencyBase[note] / (double)(1 << (8-octave));
  return ledcWriteTone(chan, noteFreq);
}

```

Although not directly compatible with Arduino's `tone()`, the function provides a dedicated interface for producing named frequencies out of the box via the `note_t` type.

```c
typedef enum {
    NOTE_C, NOTE_Cs, NOTE_D, NOTE_Eb, NOTE_E, NOTE_F, NOTE_Fs, NOTE_G, NOTE_Gs, NOTE_A, NOTE_Bb, NOTE_B, NOTE_MAX
} note_t;
```

## Example Usage
I'll take an example from [@lbernstone](https://github.com/lbernstone)'s [Tone32](https://github.com/lbernstone/Tone) library. Their library is a great solution for providing cross-compatibility between code written for an Arduino and code written for an ESP32.

```c
void loop() {
  tone(BUZZER_PIN, NOTE_C4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_D4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_E4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_F4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_G4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_A4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
  tone(BUZZER_PIN, NOTE_B4, 500, BUZZER_CHANNEL);
  noTone(BUZZER_PIN, BUZZER_CHANNEL);
}
```

In this example, a major C scale is played while holding each note for 0.5 seconds. The `BUZZER_CHANNEL` argument is optional. In the case of an ESP32, there are 16 PWM channels which can generate independent waveforms which need to explicitly assigned to any PWM-capable pin.

Here is the equivalent scale programmed using `ledcWriteNote()`.

```c
void loop() {
  ledcAttachPin(BUZZER_PIN, BUZZER_CHANNEL);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_C, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_D, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_E, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_F, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_G, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_A, 4);
  delay(500);
  ledcWriteNote(BUZZER_CHANNEL, NOTE_B, 4);
  delay(500);
  ledcDetachPin(pin)
}
```

The tradeoff here is that this is not cross-compatible with an Arduino, however, it means not having to import an external library or having to define note frequencies yourself. Similar to Arduino's `tone()`, each signal is produced at 50% duty cycle. Under the hood, both implementations are calling `ledcWriteTone`.

## References
- https://randomnerdtutorials.com/esp32-pwm-arduino-ide/
- https://github.com/espressif/arduino-esp32/issues/1720
- https://community.platformio.org/t/tone-not-working-on-espressif32-platform/7587
