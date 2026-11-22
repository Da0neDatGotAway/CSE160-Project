configuration InputBufferC {
  provides interface InputBuffer;
}

implementation {
  components InputBufferP;
  InputBuffer = InputBufferP;

  components TransportC;
  InputBufferP.Transport->TransportC;

}