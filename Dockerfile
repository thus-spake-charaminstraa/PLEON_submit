FROM pytorch/torchserve:latest
USER root
RUN apt-get update
RUN apt-get install -y libgl1-mesa-glx
RUN apt-get install -y libglib2.0-0
RUN apt-get install -y python3-distutils
COPY ./ressources/ /home/model-server/ressources/
RUN chmod -R a+rw /home/model-server/
USER model-server
RUN pip3 install --upgrade pip
RUN pip install torch-model-archiver
RUN pip install opencv-python
# RUN pip install onnx

RUN python3 -c "import cv2"
RUN pip install -r /home/model-server/ressources/yolov5/requirements.txt
EXPOSE 8080 8080
ENV PYTHONPATH "${PYTHONPATH}:/home/model-server/ressources/yolov5/"
RUN python /home/model-server/ressources/yolov5/export.py --weights /home/model-server/ressources/weights.pt --img 640 --batch 1 --include torchscript
RUN torch-model-archiver --model-name plant \
--version 0.1 --serialized-file /home/model-server/ressources/weights.torchscript \
--handler /home/model-server/ressources/torchserve_handler.py \
--extra-files /home/model-server/ressources/index_to_name.json,/home/model-server/ressources/torchserve_handler.py
RUN mv plant.mar model-store/plant.mar
CMD [ "torchserve", "--start", "--model-store", "model-store", "--models", "plant=plant.mar" ]

