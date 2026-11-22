configuration ConsumerC {
  provides interface Consumer;
}

implementation {
  components ConsumerP;
 Consumer = ConsumerP;

  components TransportC;
  ConsumerP.Transport->TransportC;

}