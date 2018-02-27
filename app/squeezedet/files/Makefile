APP = squeezedet

# Add any other object files to this list below
APP_OBJS  = main.o
# APP_OBJS += activation.o arithmetic.o bbox_utils.o display.o hungarian.o \
# 	    layer.o peta.o squeezedet.o tracker.o transform.o util.o webcam.o \
# 	    wrapper.o sim.o
APP_OBJS += activation.o arithmetic.o bbox_utils.o display.o hungarian.o \
	    layer.o peta.o squeezedet.o tracker.o transform.o util.o webcam.o \
	    wrapper.o

# CC	  = gcc-7
# CXX	  = g++-7
# CXXFLAGS += `pkg-config --cflags opencv libavcodec`
# LDLIBS   += `pkg-config --libs opencv libavcodec`

# CFLAGS += -g
# LDFLAGS += -g
FLAGS += -Wall -Wno-deprecated-declarations -Wno-pragmas -O3
FLAGS += -D__KPR_QUANT__ -D__KPR_RELEASE__
# FLAGS += -D__KPR_QUANT__ -D__KPR_DEBUG__
# FLAGS += -D__KPR_QUANT__
CFLAGS   += -std=c11 ${FLAGS}
CXXFLAGS += -std=c++14 ${FLAGS}

CXXFLAGS += -DTHREAD
CXXFLAGS += -DRELEASE

LDLIBS   += -pthread
LDLIBS   += -lavcodec -lavformat -lavutil -lswscale -lavdevice
# LDLIBS  += \
# 	-lopencv_shape \
# 	-lopencv_stitching \
# 	-lopencv_superres \
# 	-lopencv_videostab \
# 	-lopencv_aruco \
# 	-lopencv_bgsegm \
# 	-lopencv_bioinspired \
# 	-lopencv_ccalib \
# 	-lopencv_dnn \
# 	-lopencv_dpm \
# 	-lopencv_fuzzy \
# 	-lopencv_line_descriptor \
# 	-lopencv_optflow \
# 	-lopencv_plot \
# 	-lopencv_reg \
# 	-lopencv_saliency \
# 	-lopencv_stereo \
# 	-lopencv_structured_light \
# 	-lopencv_rgbd \
# 	-lopencv_surface_matching \
# 	-lopencv_tracking \
# 	-lopencv_datasets \
# 	-lopencv_text \
# 	-lopencv_face \
# 	-lopencv_video \
# 	-lopencv_ximgproc \
# 	-lopencv_calib3d \
# 	-lopencv_features2d \
# 	-lopencv_flann \
# 	-lopencv_xobjdetect \
# 	-lopencv_objdetect \
# 	-lopencv_ml \
# 	-lopencv_xphoto \
# 	-lopencv_highgui \
# 	-lopencv_videoio \
# 	-lopencv_imgcodecs \
# 	-lopencv_photo \
# 	-lopencv_imgproc \
# 	-lopencv_core
LDLIBS  += \
	-lopencv_stitching \
	-lopencv_superres \
	-lopencv_videostab \
	-lopencv_video \
	-lopencv_calib3d \
	-lopencv_features2d \
	-lopencv_flann \
	-lopencv_objdetect \
	-lopencv_ml \
	-lopencv_highgui \
	-lopencv_photo \
	-lopencv_imgproc \
	-lopencv_videoio \
	-lopencv_core

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	rm -f $(APP) $(APP_OBJS)
