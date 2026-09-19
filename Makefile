ifeq ($(OS),Windows_NT)
    RM = del /q /f
    MKDIR = if not exist $1 mkdir $1
    RMDIR = if exist $1 rmdir /s /q $1
    FixPath = $(subst /,\,$1)
    EXT = .exe
    GetFiles = $(foreach dir,$1,$(wildcard $(dir)/*$2))
    GetDirs = $(shell dir /b /s /ad $1 2>nul)
    ALL_SRC_DIRS = src $(call GetDirs,src)
    SRCS = $(call GetFiles,$(ALL_SRC_DIRS),.cpp)
    ALL_HDR_DIRS = headers $(call GetDirs,headers)
    RUN_CMD = $(TARGET)
    RUN_TESTS = for %%f in ($(subst /,\,$(TEST_BINS))) do %%f
else
    RM = rm -f
    MKDIR = mkdir -p $1
    RMDIR = rm -rf $1
    FixPath = $1
    EXT =
    GetFiles = $(shell find $1 -type f -name "*$2" 2>/dev/null)
    GetDirs = $(shell find $1 -type d 2>/dev/null)
    SRCS = $(call GetFiles,src,.cpp)
    ALL_HDR_DIRS = $(call GetDirs,headers)
    RUN_CMD = ./$(TARGET)
    RUN_TESTS = for bin in $(TEST_BINS); do ./$$bin; done
endif

CXX = g++
CXXFLAGS = -Wall $(addprefix -I,$(ALL_HDR_DIRS)) -MMD -MP

BUILD_DIR = build
OBJS = $(patsubst src/%.cpp, $(BUILD_DIR)/%.o, $(SRCS))
DEPS = $(OBJS:.o=.d)

TARGET = main$(EXT)

TEST_SRCS = $(call GetFiles,tests/unit,.cpp)
TEST_BINS = $(patsubst tests/unit/%.cpp, $(BUILD_DIR)/tests/%.test$(EXT), $(TEST_SRCS))

.PHONY: all run clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS)

-include $(DEPS)

$(BUILD_DIR)/%.o: src/%.cpp
	$(call MKDIR,$(call FixPath,$(dir $@)))
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/tests/%.test$(EXT): tests/unit/%.cpp
	$(call MKDIR,$(call FixPath,$(dir $@)))
	$(CXX) $(CXXFLAGS) $< $(filter-out $(BUILD_DIR)/main.o, $(OBJS)) -o $@

test: $(TEST_BINS)
	$(RUN_TESTS)

run: $(TARGET)
	$(RUN_CMD)

clean:
	$(call RMDIR,$(BUILD_DIR))
	$(RM) $(call FixPath,$(TARGET))
