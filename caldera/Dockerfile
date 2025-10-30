FROM python:3.9-slim
WORKDIR /usr/src/app
COPY . .
RUN pip install -r requirements.txt || echo "No requirements.txt found"
EXPOSE 8888
CMD ["python", "server.py"]
