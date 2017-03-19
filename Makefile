CFLAGS = -arch=sm_35 -rdc=true
OBJS = bjSim.o gameTree.o Deck.o init.o bjState.o evalHand.o
HEADERS = includes.h externs.h

bjSim: $(OBJS)
	nvcc $(CFLAGS) -o $@ $(OBJS)

bjSim.o: $(HEADERS) bjSim.cu
	nvcc $(CFLAGS) -c bjSim.cu

bjState.o: $(HEADERS) bjState.h bjState.cu
	nvcc $(CFLAGS) -c bjState.cu

init.o: $(HEADERS) init.cu
	nvcc $(CFLAGS) -c init.cu

Deck.o: $(HEADERS) Deck.cu
	nvcc $(CFLAGS) -c Deck.cu

evalHand.o: $(HEADERS) evalHand.cu
	nvcc $(CFLAGS) -c evalHand.cu

clean:
	rm -f bjcuda bjSim *.o

%.o: %.cpp
	g++ $(CFLAGS) -c $<

%.o: %.cu
	nvcc $(CFLAGS) -c $<
