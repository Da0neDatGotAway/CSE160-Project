enum{
    MAP_SIZE = 255,
    N_FORGET_WEIGHT = 15000
};

typedef struct neighbor{
	uint8_t id;
    /*
     * We use the link value to know how good our connection is. We do this
     * using the previous time with a exponantially wheighted moving average.
     * Seperately however we also record the last time we recieved a packet.
     * We do *this* because I am too lazy to solve the weighted average right 
     * now.
     */
     uint32_t linkValue;
     uint32_t lastRecieveTime;
}neighbor;