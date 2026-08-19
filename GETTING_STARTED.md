# 🚀 Guia de Inicialização — ProjectNBX

Este documento contém o passo a passo completo para configurar o ambiente e rodar o **ProjectNBX** na sua máquina local.

---

## 📋 1. Pré-requisitos

Antes de iniciar, certifique-se de ter instalado:

1. **Git:** [Download Git](https://git-scm.com/)
2. **FVM (Flutter Version Management):**
   ```bash
   dart pub global activate fvm
   ```
3. **Para Windows Desktop (Obrigatório):**
   - **[Visual Studio Community 2022](https://visualstudio.microsoft.com/pt-br/downloads/)** com a carga de trabalho:
     👉 **"Desenvolvimento para desktop com C++"** (*Desktop development with C++*).

---

## 🛠️ 2. Configurando o Projeto pela Primeira Vez

Abra o terminal na pasta do projeto (`D:\Github\My\projectNBX`) e execute:

```bash
# 1. Travar a versão do Flutter no canal estável (Flutter 3.41.x / Dart 3.11.x)
fvm use stable

# 2. Baixar todas as dependências do projeto
fvm flutter pub get
```

---

## 🖥️ 3. Como Executar

### 🪟 Windows (Desktop)
```bash
fvm flutter run -d windows
```

### 🌐 Web (Google Chrome / Edge)
```bash
fvm flutter run -d chrome
```

### 📱 Android / iOS
Com o celular conectado via USB (com Depuração USB ativada) ou com um emulador aberto:
```bash
# Ver dispositivos disponíveis
fvm flutter devices

# Rodar no dispositivo
fvm flutter run
```

---

## ⌨️ 4. Atalhos Úteis no Terminal Durante o Desenvolvimento

Quando o aplicativo estiver rodando com `flutter run`, use estes comandos no terminal:
* `r` — **Hot Reload** (atualiza a tela quase instantaneamente mantendo o estado).
* `R` — **Hot Restart** (reinicia a aplicação rapidamente).
* `h` — Lista de todos os comandos de debug e inspeção.
* `q` — Encerra a execução do aplicativo.

---

## ❓ 5. Resolução de Problemas Comuns

### ❌ Erro: *Unable to find suitable Visual Studio toolchain*
- **Causa:** O compilador C++ da Microsoft não foi detectado.
- **Solução:** Abra o *Visual Studio Installer*, clique em *Modificar* na sua versão do Visual Studio 2022 e certifique-se de que a opção **"Desenvolvimento para desktop com C++"** está marcada e instalada. Reinicie o terminal do VS Code após a instalação.

### ❌ Erro: *Android licenses not accepted*
- **Solução:** Execute no terminal:
  ```bash
  fvm flutter doctor --android-licenses
  ```
  e digite `y` para aceitar os termos.

### 🔍 Verificar Saúde do Ambiente:
```bash
fvm flutter doctor
```
