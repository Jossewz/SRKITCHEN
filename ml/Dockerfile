FROM python:3.12-slim

WORKDIR /app

# Instalar dependencias del sistema requeridas
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el codigo del microservicio ML
COPY . .

# Exponer el puerto
ENV PORT=8000
EXPOSE 8000

# Comando de ejecucion
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
