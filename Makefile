CFLAGS = -arch=sm_35 -rdc=true
OBJS = bjcuda.o initbj.o State.o Deck.o Sarsa.o playHand.o evalHand.o
HEADERS = includes.h externs.h

bjcuda: $(OBJS)
	nvcc $(CFLAGS) -o $@ $(OBJS)

clean:
	rm -f bjcuda *.o

%.o: %.cpp
	g++ $(CFLAGS) -c $<

%.o: %.cu
	nvcc $(CFLAGS) -c $<
