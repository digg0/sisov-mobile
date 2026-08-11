# Configuração do Login Google

Client IDs OAuth são identificadores públicos (não são secrets). O Client ID
Web do SISOV está configurado como padrão no app e ainda pode ser substituído
por `--dart-define`.

## 1. Criar projeto e tela de consentimento

1. No Google Cloud Console, crie ou selecione o projeto do SISOV.
2. Em **Google Auth Platform**, configure a marca e a tela de consentimento.
3. Solicite apenas os escopos básicos `openid`, `email` e `profile`.
4. Enquanto o app estiver em teste, adicione as contas autorizadas como
   usuários de teste.

## 2. Credencial Android

O pacote definitivo do aplicativo é:

```text
br.com.sisov.mobile
```

Crie um OAuth Client ID do tipo **Android** com esse pacote e o SHA-1 da chave.
O Client ID Android atual é:

```text
606575197535-brg5kvb5d4tr6tlvua1vahlofhbulvrs.apps.googleusercontent.com
```

Para consultar o SHA-1 de desenvolvimento:

```powershell
cd android
.\gradlew signingReport
```

Antes de publicar, crie a chave de release e cadastre também o SHA-1 dela. O
APK atualmente ainda usa assinatura de desenvolvimento e deve ser migrado para
uma keystore de release antes da Play Store.

## 3. Credencial Web

Crie um OAuth Client ID do tipo **Aplicativo da Web**.

Origens JavaScript para desenvolvimento:

```text
http://localhost
http://localhost:3000
https://sisov.com.br
```

Client ID Web atual:

```text
606575197535-ebgklfv1hls80g5fccfs8ronpaihcd4h.apps.googleusercontent.com
```

Execute o Flutter Web sempre em uma origem cadastrada:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 3000 `
  --dart-define=GOOGLE_WEB_CLIENT_ID=606575197535-ebgklfv1hls80g5fccfs8ronpaihcd4h.apps.googleusercontent.com
```

O botão Web é renderizado pelo Google Identity Services. O Client ID é passado
programaticamente pelo Dart, portanto não é gravado em `web/index.html`.

## 4. Backend no Render

No serviço da API, configure:

```text
GOOGLE_CLIENT_IDS=606575197535-ebgklfv1hls80g5fccfs8ronpaihcd4h.apps.googleusercontent.com,606575197535-brg5kvb5d4tr6tlvua1vahlofhbulvrs.apps.googleusercontent.com
```

O backend valida assinatura, emissor, expiração, audiência e e-mail verificado
do ID token. Nunca envie um client secret ao aplicativo Flutter.

## 5. Build Android

O Client ID usado como audiência do backend é o Client ID Web:

```powershell
flutter build apk --release `
  --dart-define=GOOGLE_WEB_CLIENT_ID=606575197535-ebgklfv1hls80g5fccfs8ronpaihcd4h.apps.googleusercontent.com
```

Sem o `--dart-define`, o app usa o Client ID Web padrão acima.

## Fluxo de primeiro acesso

- Conta já cadastrada com o mesmo e-mail verificado: o Google é vinculado e o
  login é concluído.
- Conta nova: o app solicita CPF/CNPJ; somente depois o produtor e a sessão
  SISOV são criados.
