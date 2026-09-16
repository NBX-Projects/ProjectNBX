import 'package:projectnbx/core/localization/app_language.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isPt => language == AppLanguage.pt;

  // Common
  String get appTitle => 'NBX PROJECT';
  String get searchPlaceholder => isPt ? 'Buscar servidores, canais, membros...' : 'Search servers, channels, members...';
  String get inCallsBadge => isPt ? 'em chamadas' : 'in calls';
  String get afk => 'AFK';
  String get online => isPt ? 'Online' : 'Online';
  String get idle => isPt ? 'Ausente' : 'Away';
  String get dnd => isPt ? 'Não Perturbe' : 'Do Not Disturb';
  String get connected => isPt ? 'CONECTADO' : 'CONNECTED';
  String get active => isPt ? 'ATIVO' : 'ACTIVE';
  String get cancel => isPt ? 'Cancelar' : 'Cancel';
  String get save => isPt ? 'Salvar' : 'Save';
  String get close => isPt ? 'Fechar' : 'Close';
  String get underConstruction => isPt ? 'Funcionalidade em desenvolvimento 🚧' : 'Feature under development 🚧';

  // Navigation
  String get navHome => isPt ? 'Início' : 'Home';
  String get navFavorites => isPt ? 'Favoritos' : 'Favorites';
  String get navTrending => isPt ? 'Em Alta' : 'Trending';
  String get navDMs => isPt ? 'Amigos & Conversas' : 'Friends & DMs';
  String get navVoice => isPt ? 'Salas de Voz' : 'Voice Lounges';
  String get navExplore => isPt ? 'Explorar' : 'Explore';
  String get navSettings => isPt ? 'Configurações' : 'Settings';

  // Home / Hub
  String get hubTitle => isPt ? 'Início' : 'Home';
  String hubSubtitle(int serversCount, int voiceCount) => isPt
      ? '$serversCount comunidades · $voiceCount em chamadas agora'
      : '$serversCount communities · $voiceCount in calls now';
  String get myServers => isPt ? 'MEUS SERVIDORES' : 'MY SERVERS';
  String get createServer => isPt ? 'Criar Servidor' : 'Create Server';
  String get createServerSubtitle => isPt
      ? 'Adicione seu espaço exclusivo para voz e chat'
      : 'Add your custom space for voice and chat';
  String get clickToCreate => isPt ? 'Clique para Criar' : 'Click to Create';

  // Create Server Dialog
  String get dialogCreateServerTitle => isPt ? 'Criar seu Servidor' : 'Create your Server';
  String get dialogCreateServerDescription => isPt
      ? 'Seu servidor é onde você e seus amigos ou time se reúnem. Crie canais organizados para áudio cristalino e conversas.'
      : 'Your server is where you and your team or friends hang out. Create channels for crystal-clear voice and chat.';
  String get serverNameLabel => isPt ? 'NOME DO SERVIDOR' : 'SERVER NAME';
  String get serverNamePlaceholder => isPt ? 'Ex: Squad Gamer ou Dev Lounge' : 'e.g. Gamer Squad or Dev Lounge';
  String get serverIconLabel => isPt ? 'URL DO ÍCONE / BANNER (OPCIONAL)' : 'ICON / BANNER URL (OPTIONAL)';
  String get serverNameRequired => isPt ? 'Por favor, informe o nome do servidor.' : 'Please provide a server name.';
  String serverCreatedSuccess(String name) => isPt ? 'Servidor "$name" criado com sucesso!' : 'Server "$name" created successfully!';

  // Right Panel / Feed
  String get recentActivity => isPt ? 'ATIVIDADE RECENTE' : 'RECENT ACTIVITY';
  String get noNotificationsTitle => isPt ? 'Nenhuma notificação' : 'No notifications';
  String get noNotificationsSubtitle => isPt
      ? 'Novas mensagens e menções aparecerão aqui em tempo real.'
      : 'New messages and mentions will show up here in real time.';
  String get upcomingEvents => isPt ? 'PRÓXIMOS EVENTOS' : 'UPCOMING EVENTS';
  String get noEventsTitle => isPt ? 'Sem eventos agendados' : 'No upcoming events';
  String get noEventsSubtitle => isPt
      ? 'Eventos criados nos seus servidores serão listados aqui.'
      : 'Events created in your servers will be listed here.';
  String get communitySummary => isPt ? 'RESUMO DE COMUNIDADES' : 'COMMUNITY SUMMARY';
  String get createFirstCommunityTitle => isPt ? 'Crie sua primeira comunidade' : 'Create your first community';
  String get createFirstCommunitySubtitle => isPt
      ? 'Inicie um espaço para conversas de texto e chamadas de voz.'
      : 'Start a space for text channels and voice calls.';
  String get systemAndNetwork => isPt ? 'SISTEMA & REDE' : 'SYSTEM & NETWORK';
  String get databaseService => isPt ? 'Banco de Dados & Storage' : 'Database & Storage';
  String get voiceService => isPt ? 'Servidor de Voz & Baixa Latência' : 'Voice Server & Low Latency';
  String get ready => isPt ? 'Pronto' : 'Ready';

  // Settings
  String get settingsTitle => isPt ? 'CONFIGURAÇÕES' : 'SETTINGS';
  String get userCategory => isPt ? 'USUÁRIO' : 'USER';
  String get myAccount => isPt ? 'Minha Conta' : 'My Account';
  String get accountDescription => isPt
      ? 'Gerencie seus dados de perfil e preferências de acesso'
      : 'Manage your profile details and access preferences';
  String get currentStatus => isPt ? 'Status de Presença' : 'Presence Status';
  String get currentStatusOnline => isPt ? 'Online e Disponível' : 'Online & Available';
  String get currentStatusAway => isPt ? 'Ausente' : 'Away';
  String get securitySession => isPt ? 'Sessão & Segurança' : 'Session & Security';
  String get sessionActive => isPt ? 'Sessão criptografada e autenticada' : 'Encrypted & authenticated session';

  String get appearanceAndLanguage => isPt ? 'Aparência & Idioma' : 'Appearance & Language';
  String get appearanceDescription => isPt
      ? 'Personalize o tema visual e a linguagem da interface'
      : 'Customize visual theme and interface language';
  String get themeSelector => isPt ? 'SELETOR DE TEMA' : 'THEME SELECTOR';
  String get darkThemeTitle => isPt ? 'Pastel Tech (Escuro)' : 'Pastel Tech (Dark)';
  String get darkThemeSubtitle => isPt ? 'Carvão profundo & pêssego mineral' : 'Deep charcoal & mineral peach';
  String get lightThemeTitle => isPt ? 'Forest Slate (Claro)' : 'Forest Slate (Light)';
  String get lightThemeSubtitle => isPt ? 'Creme alabastro & verde floresta' : 'Alabaster cream & forest sage';
  String get languageSelector => isPt ? 'IDIOMA DA APLICAÇÃO' : 'APP LANGUAGE';

  String get voiceAndVideo => isPt ? 'Voz & Áudio' : 'Voice & Audio';
  String get voiceDescription => isPt
      ? 'Configurações de dispositivos de som e transmissão de alta performance'
      : 'Settings for audio devices and high-performance transmission';
  String get inputDevice => isPt ? 'DISPOSITIVO DE ENTRADA (MICROFONE)' : 'INPUT DEVICE (MICROPHONE)';
  String get outputDevice => isPt ? 'DISPOSITIVO DE SAÍDA (FONES / ALTO-FALANTES)' : 'OUTPUT DEVICE (HEADPHONES / SPEAKERS)';
  String get inputVolume => isPt ? 'Volume de Entrada' : 'Input Volume';
  String get outputVolume => isPt ? 'Volume de Saída' : 'Output Volume';
  String get audioProcessing => isPt ? 'PROCESSAMENTO DE ÁUDIO' : 'AUDIO PROCESSING';
  String get noiseSuppression => isPt ? 'Supressão de Ruído de Fundo' : 'Background Noise Suppression';
  String get noiseSuppressionDesc => isPt
      ? 'Filtra ventilação, zumbidos elétricos e ruídos constantes da sala'
      : 'Filters fan noise, electrical hum, and constant ambient noise';
  String get typingNoiseSuppression => isPt ? 'Supressão de Teclado & Cliques' : 'Keyboard & Click Suppression';
  String get typingNoiseSuppressionDesc => isPt
      ? 'Atenua cliques de teclas mecânicas e cliques de mouse durante a fala'
      : 'Attenuates mechanical keyboard clicks and mouse clicks while speaking';
  String get echoCancellation => isPt ? 'Cancelamento de Eco Acústico' : 'Acoustic Echo Cancellation';
  String get echoCancellationDesc => isPt
      ? 'Evita retorno de áudio durante chamadas coletivas'
      : 'Prevents audio feedback during group calls';
  String get compressor => isPt ? 'Compressor de Áudio / Ganho Automático (AGC)' : 'Audio Compressor / Auto Gain (AGC)';
  String get compressorDesc => isPt
      ? 'Normaliza o volume da voz, reduz picos altos e amplifica falas baixas'
      : 'Normalizes voice volume, prevents clipping peaks, and boosts quiet speech';
  String get highPassFilter => isPt ? 'Filtro High-Pass' : 'High-Pass Filter';
  String get highPassFilterDesc => isPt
      ? 'Atenua frequências graves indesejadas, vibrações de mesa e sopros'
      : 'Attenuates low rumble, desk vibrations, and plosives';
  String get vadOptimization => isPt ? 'Transmissão Inteligente de Voz (VAD)' : 'Smart Voice Transmission (VAD)';
  String get vadOptimizationDesc => isPt
      ? 'Transmite apenas quando a voz for detectada para máxima estabilidade'
      : 'Transmits only when voice is detected for peak stability';

  // Noise Gate / Input Sensitivity
  String get inputSensitivity => isPt ? 'SENSIBILIDADE DE ENTRADA & GATE DE RUÍDO' : 'INPUT SENSITIVITY & NOISE GATE';
  String get inputSensitivityDesc => isPt
      ? 'Define o limiar mínimo de som para o microfone abrir a transmissão'
      : 'Determines the minimum sound level required for the mic to transmit';
  String get autoSensitivity => isPt ? 'Sensibilidade de Entrada Automática' : 'Automatic Input Sensitivity';
  String get autoSensitivityDesc => isPt
      ? 'O sistema calibra dinamicamente o corte de ruído de acordo com a sala'
      : 'The system dynamically calibrates the noise cut according to your room';
  String get noiseGateThreshold => isPt ? 'Limiar de Corte (Noise Gate)' : 'Cutoff Threshold (Noise Gate)';
  String get noiseGateThresholdDesc => isPt
      ? 'Sons abaixo deste nível (ex: teclas e respiração) permanecem em silêncio'
      : 'Sounds below this level (e.g. keystrokes and breathing) remain muted';
  String get noiseGateRelease => isPt ? 'Tempo de Liberação (Hangover)' : 'Release Time (Hangover)';
  String get noiseGateReleaseDesc => isPt
      ? 'Mantém o microfone aberto por breves momentos para não cortar o fim das frases'
      : 'Keeps the mic open briefly to avoid cutting off the end of words';

  String get hotkeysAndPTT => isPt ? 'Atalhos & Push-to-Talk' : 'Shortcuts & Push-to-Talk';
  String get hotkeysDescription => isPt
      ? 'Defina o modo de fala e atalhos rápidos de teclado'
      : 'Set your speech mode and quick keyboard shortcuts';
  String get inputMode => isPt ? 'MODO DE FALA' : 'INPUT MODE';
  String get voiceActivity => isPt ? 'Ativação por Voz' : 'Voice Activity';
  String get voiceActivityDesc => isPt
      ? 'Microfone ativa automaticamente ao falar (VAD)'
      : 'Microphone activates automatically when you speak';
  String get pushToTalk => isPt ? 'Push-to-Talk (PTT)' : 'Push-to-Talk (PTT)';
  String get pushToTalkDesc => isPt
      ? 'Pressione uma tecla para transmitir seu áudio'
      : 'Hold a key to transmit your voice';
  String get pttKeyLabel => isPt ? 'Tecla de Push-to-Talk' : 'Push-to-Talk Key';
  String get pttKeyDesc => isPt ? 'Pressione para falar em chamadas' : 'Hold to speak during voice calls';

  String get globalShortcuts => isPt ? 'ATALHOS GLOBAIS DO SISTEMA' : 'GLOBAL SYSTEM SHORTCUTS';
  String get muteUnmuteAction => isPt ? 'Mutar / Desmutar Microfone' : 'Mute / Unmute Microphone';
  String get deafenAction => isPt ? 'Desativar / Ativar Áudio' : 'Deafen / Undeafen Audio';
  String get searchShortcut => isPt ? 'Buscar Servidores e Canais' : 'Search Servers and Channels';
  String get toggleThemeShortcut => isPt ? 'Alternar Tema Claro / Escuro' : 'Toggle Light / Dark Theme';

  String get systemStatusTitle => isPt ? 'Status dos Serviços & Conexão' : 'Services & Connection Status';
  String get systemStatusDesc => isPt
      ? 'Monitoramento de integridade da infraestrutura e comunicação em tempo real'
      : 'Infrastructure health and real-time communication monitoring';
  String get logOut => isPt ? 'Encerrar Sessão' : 'Log Out';
}
