CFLAGS = -arch=sm_35 -rdc=true
OBJS = bjSim.o gameTree.o Deck.o init.o bjState.o

bjSim: $(OBJS)
	nvcc $(CFLAGS) -o $@ $(OBJS)

bjcuda: play.o Deck.o init.o
	nvcc $(CFLAGS) -o $@ play.o Deck.o init.o

play.o: includes.h play.cu
	nvcc $(CFLAGS) -c play.cu

init.o: includes.h init.cu
	nvcc $(CFLAGS) -c init.cu

Deck.o: includes.h Deck.cu
	nvcc $(CFLAGS) -c Deck.cu

clean:
	rm -f bjcuda bjSim *.o

%.o: %.cpp
	g++ $(CFLAGS) -c $<

%.o: %.cu
	nvcc $(CFLAGS) -c $<
