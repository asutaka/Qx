// Game State
let gameState = {
  nickname: "Player_1",
  gold: 2000,
  accumulatedGold: 2000,
  singleHighScore: 0,
  volume: 80,
  lastDailyClaim: 0,
  currentScreen: "lobby",
  
  // New States: Language & Translation
  targetLanguage: "en",
  downloadedLanguages: ["en", "vi"], // vi is preloaded
  
  // New States: Shop & Customization
  ownedItems: ["hat_none", "shoes_none", "effect_none"],
  equippedHat: "hat_none",
  equippedShoes: "shoes_none",
  equippedEffect: "effect_none"
};

// Shop Items Database
const SHOP_ITEMS = {
  hat: [
    { id: "hat_none", name: "Không đội mũ", price: 0, emoji: "" },
    { id: "hat_cowboy", name: "Mũ Cao Bồi 🤠", price: 500, emoji: "🤠" },
    { id: "hat_crown", name: "Vương Miện 👑", price: 1500, emoji: "👑" }
  ],
  shoes: [
    { id: "shoes_none", name: "Không đi giày", price: 0, emoji: "" },
    { id: "shoes_running", name: "Giày Thể Thao 👟", price: 300, emoji: "👟" },
    { id: "shoes_gold", name: "Bốt Vàng 🥾", price: 1000, emoji: "🥾" }
  ],
  effect: [
    { id: "effect_none", name: "Không hiệu ứng", price: 0, emoji: "" },
    { id: "effect_fire", name: "Vệt Lửa 🔥", price: 800, emoji: "🔥" },
    { id: "effect_rainbow", name: "Cầu Vồng 🌈", price: 1200, emoji: "🌈" }
  ]
};

let currentShopCategory = "hat";

// Play State (Single Mode)
let singleState = {
  currentQuestion: null,
  level: 1,
  correctAnswers: 0,
  isTranslated: false,
  doubleAnswerActive: false,
  doubleAnswerUsedThisQuestion: false,
  wrongAnswersSelected: [],
  lifelines: {
    fiftyFifty: true,
    doubleAnswer: true,
    changeQuestion: true
  }
};

// Play State (Battle Mode)
let battleState = {
  currentQuestion: null,
  questionIndex: 0, // 0 to 9 (10 questions)
  playerScore: 0,
  botScore: 0,
  timer: 30,
  timerInterval: null,
  playerAnswered: false,
  playerSelectedIdx: null,
  botAnswered: false,
  botSelectedIdx: null,
  showAnswerTimeout: null,
  isTranslated: false,
  botCorrectProbabilities: [0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.5, 0.4] // Difficulty 1-10
};

// Mock Leaderboards
const mockSingleRank = [
  { nickname: "ProQuizzer", score: 87 },
  { nickname: "TriviaGod", score: 75 },
  { nickname: "Brainiac_99", score: 62 },
  { nickname: "MasterMind", score: 50 },
  { nickname: "NoobPlayer", score: 12 }
];

const mockGoldRank = [
  { nickname: "GoldHoarder", gold: 15200 },
  { nickname: "BetKing", gold: 12000 },
  { nickname: "TriviaGod", gold: 9800 },
  { nickname: "LuckyCharms", gold: 7500 },
  { nickname: "RichieRich", gold: 5000 }
];

// Sound Synthesizer (Web Audio API)
const AudioCtx = window.AudioContext || window.webkitAudioContext;
let audioCtx = null;

function initAudio() {
  if (!audioCtx) {
    audioCtx = new AudioCtx();
  }
}

function playSound(type) {
  if (gameState.volume === 0) return;
  initAudio();
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }

  const volumeNode = audioCtx.createGain();
  volumeNode.gain.setValueAtTime((gameState.volume / 100) * 0.1, audioCtx.currentTime);
  volumeNode.connect(audioCtx.destination);

  const osc = audioCtx.createOscillator();
  osc.connect(volumeNode);

  if (type === 'click') {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(600, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(150, audioCtx.currentTime + 0.1);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.1);
  } else if (type === 'correct') {
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(523.25, audioCtx.currentTime); // C5
    osc.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.1); // E5
    osc.frequency.setValueAtTime(783.99, audioCtx.currentTime + 0.2); // G5
    osc.frequency.setValueAtTime(1046.50, audioCtx.currentTime + 0.3); // C6
    osc.start();
    osc.stop(audioCtx.currentTime + 0.5);
  } else if (type === 'wrong') {
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(220, audioCtx.currentTime); // A3
    osc.frequency.exponentialRampToValueAtTime(110, audioCtx.currentTime + 0.4);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.4);
  } else if (type === 'countdown') {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(440, audioCtx.currentTime);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.05);
  } else if (type === 'win') {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(523.25, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(880, audioCtx.currentTime + 0.5);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.5);
  }
}

// Save & Load State
function loadGameData() {
  const saved = localStorage.getItem("antigravity_quiz_state");
  if (saved) {
    try {
      const parsed = JSON.parse(saved);
      gameState = { ...gameState, ...parsed };
      // Safeguard new states
      if (!gameState.downloadedLanguages) gameState.downloadedLanguages = ["en", "vi"];
      if (!gameState.ownedItems) gameState.ownedItems = ["hat_none", "shoes_none", "effect_none"];
      if (!gameState.equippedHat) gameState.equippedHat = "hat_none";
      if (!gameState.equippedShoes) gameState.equippedShoes = "shoes_none";
      if (!gameState.equippedEffect) gameState.equippedEffect = "effect_none";
      if (!gameState.targetLanguage) gameState.targetLanguage = "en";
    } catch (e) {
      console.error("Error loading state", e);
    }
  }
  updateUIHeader();
}

function saveGameData() {
  localStorage.setItem("antigravity_quiz_state", JSON.stringify(gameState));
}

function getPlayerLevelTitle(highScore) {
  if (highScore < 10) return "Newbie";
  if (highScore < 25) return "Tập sự";
  if (highScore < 50) return "Có hiểu biết";
  if (highScore < 75) return "Chuyên gia";
  if (highScore < 95) return "Nhà thông thái";
  return "Phù thủy";
}

// UI Updates
function updateUIHeader() {
  document.getElementById("nickname-val").textContent = gameState.nickname;
  document.getElementById("avatar-letter").textContent = gameState.nickname.charAt(0).toUpperCase();
  document.getElementById("gold-val").textContent = gameState.gold;
  
  // Cập nhật cấp hiệu của người chơi dựa trên High Score ở Single Mode
  const levelTitle = getPlayerLevelTitle(gameState.singleHighScore);
  const lvlEl = document.getElementById("user-level-val");
  if (lvlEl) {
    lvlEl.textContent = levelTitle;
  }
}

// Navigation
function showScreen(screenId) {
  playSound('click');
  
  // Hide topbar (header) and bottombar (footer) in single mode (quiz) and battle mode
  const header = document.querySelector(".game-header");
  const footer = document.querySelector(".game-footer");
  if (screenId === "quiz" || screenId === "battle") {
    if (header) header.classList.add("hidden");
    if (footer) footer.classList.add("hidden");
  } else {
    if (header) header.classList.remove("hidden");
    if (footer) footer.classList.remove("hidden");
  }

  document.querySelectorAll(".game-screen").forEach(s => s.classList.add("hidden"));
  document.getElementById(`${screenId}-screen`).classList.remove("hidden");
  
  // Update footer tabs active state
  document.querySelectorAll(".nav-tab").forEach(tab => {
    if (tab.dataset.screen === screenId) {
      tab.classList.add("active");
    } else {
      tab.classList.remove("active");
    }
  });

  // Screen specific initializers
  if (screenId === "lobby") {
    checkDailyRewardButton();
  } else if (screenId === "settings") {
    document.getElementById("input-nickname").value = gameState.nickname;
    document.getElementById("input-volume").value = gameState.volume;
    document.getElementById("volume-val").textContent = gameState.volume + "%";
    document.getElementById("select-language").value = gameState.targetLanguage;
  } else if (screenId === "rank") {
    renderLeaderboard("single");
  } else if (screenId === "shop") {
    renderShop();
  }

  // Clear running timers if leaving screens
  if (screenId !== "quiz") {
    // Reset any state
  }
  if (screenId !== "battle") {
    clearInterval(battleState.timerInterval);
    clearTimeout(battleState.showAnswerTimeout);
  }

  gameState.currentScreen = screenId;
}

// Daily Reward Logic
function checkDailyRewardButton() {
  const now = Date.now();
  const oneDay = 24 * 60 * 60 * 1000;
  const btn = document.getElementById("claim-daily-btn");
  
  if (now - gameState.lastDailyClaim < oneDay) {
    btn.disabled = true;
    const timeLeft = oneDay - (now - gameState.lastDailyClaim);
    const hours = Math.floor(timeLeft / (60 * 60 * 1000));
    const mins = Math.floor((timeLeft % (60 * 60 * 1000)) / (60 * 1000));
    btn.textContent = `Claimed (${hours}h ${mins}m)`;
  } else {
    btn.disabled = false;
    btn.textContent = "Claim 1,000";
  }
}

function claimDailyReward() {
  gameState.gold += 1000;
  gameState.accumulatedGold += 1000;
  gameState.lastDailyClaim = Date.now();
  saveGameData();
  updateUIHeader();
  checkDailyRewardButton();
  playSound('correct');
  
  // Show animation or alert
  alert("You claimed 1,000 Gold Daily Login Bonus!");
}

// ----------------------------------------------------
// SINGLE MODE LOGIC (Who Wants To Be A Millionaire)
// ----------------------------------------------------
function startSingleGame() {
  singleState = {
    currentQuestion: null,
    level: 1,
    correctAnswers: 0,
    isTranslated: false,
    doubleAnswerActive: false,
    doubleAnswerUsedThisQuestion: false,
    wrongAnswersSelected: [],
    lifelines: {
      fiftyFifty: true,
      doubleAnswer: true,
      changeQuestion: true
    }
  };
  
  updateLifelineButtons();
  loadSingleQuestion();
  showScreen("quiz");
}

function loadSingleQuestion() {
  // Logic phân cấp độ khó của Open Trivia DB:
  // - 10 câu đầu (level 1-10): Easy (trong prototype lấy từ level 1-3)
  // - 20 câu tiếp (level 11-30): Medium (trong prototype lấy từ level 4-7)
  // - Các câu sau (level 31+): Hard (trong prototype lấy từ level 8-10)
  let mockQuestionLevel;
  if (singleState.level <= 10) {
    mockQuestionLevel = 1 + Math.floor(Math.random() * 3); // Lấy ngẫu nhiên level 1, 2, 3
  } else if (singleState.level <= 30) {
    mockQuestionLevel = 4 + Math.floor(Math.random() * 4); // Lấy ngẫu nhiên level 4, 5, 6, 7
  } else {
    mockQuestionLevel = 8 + Math.floor(Math.random() * 3); // Lấy ngẫu nhiên level 8, 9, 10
  }

  singleState.currentQuestion = getQuestion(mockQuestionLevel);
  singleState.wrongAnswersSelected = [];
  singleState.doubleAnswerUsedThisQuestion = false;
  
  document.getElementById("single-question-num").textContent = `Question ${singleState.level} / 100`;
  renderQuestionCard(singleState.currentQuestion, singleState.isTranslated, "single");
}

function updateLifelineButtons() {
  const btn50 = document.getElementById("lifeline-50");
  const btnDouble = document.getElementById("lifeline-double");
  const btnChange = document.getElementById("lifeline-change");
  
  btn50.disabled = !singleState.lifelines.fiftyFifty;
  btnDouble.disabled = !singleState.lifelines.doubleAnswer;
  btnChange.disabled = !singleState.lifelines.changeQuestion;
}

function useFiftyFifty() {
  if (!singleState.lifelines.fiftyFifty) return;
  playSound('click');
  singleState.lifelines.fiftyFifty = false;
  updateLifelineButtons();
  
  const correctIdx = singleState.currentQuestion.answer;
  let wrongIndices = [0, 1, 2, 3].filter(idx => idx !== correctIdx);
  
  // Shuffle wrong indices and take 2 to hide
  wrongIndices.sort(() => Math.random() - 0.5);
  const hiddenIdx1 = wrongIndices[0];
  const hiddenIdx2 = wrongIndices[1];
  
  const optionButtons = document.querySelectorAll("#single-options-container .option-btn");
  optionButtons[hiddenIdx1].classList.add("faded");
  optionButtons[hiddenIdx1].disabled = true;
  optionButtons[hiddenIdx2].classList.add("faded");
  optionButtons[hiddenIdx2].disabled = true;
}

// Change current question
function useChangeQuestion() {
  if (!singleState.lifelines.changeQuestion) return;
  playSound('click');
  singleState.lifelines.changeQuestion = false;
  updateLifelineButtons();
  loadSingleQuestion();
}

function useDoubleAnswer() {
  if (!singleState.lifelines.doubleAnswer) return;
  playSound('click');
  
  // Trigger Simulated CrazyGames Ads
  showSimulatedAd(() => {
    // Grant lifeline reward on completion
    singleState.lifelines.doubleAnswer = false;
    singleState.doubleAnswerActive = true;
    updateLifelineButtons();
    alert("Quyền trợ giúp Trả Lời 2 Lần đã được kích hoạt cho câu hỏi này!");
  });
}

function toggleTranslation(mode) {
  playSound('click');
  if (mode === "single") {
    singleState.isTranslated = !singleState.isTranslated;
    const transBtn = document.getElementById("single-translate-btn");
    if (singleState.isTranslated) transBtn.classList.add("active");
    else transBtn.classList.remove("active");
    renderQuestionCard(singleState.currentQuestion, singleState.isTranslated, "single");
  } else if (mode === "battle") {
    battleState.isTranslated = !battleState.isTranslated;
    const transBtn = document.getElementById("battle-translate-btn");
    if (battleState.isTranslated) transBtn.classList.add("active");
    else transBtn.classList.remove("active");
    renderQuestionCard(battleState.currentQuestion, battleState.isTranslated, "battle");
  }
}

function renderQuestionCard(questionObj, isTranslated, mode) {
  const container = document.getElementById(mode === "single" ? "single-question-container" : "battle-question-container");
  const optionsContainer = document.getElementById(mode === "single" ? "single-options-container" : "battle-options-container");
  
  const langCode = gameState.targetLanguage;
  
  // If translation is triggered but target language is English, prompt user
  if (isTranslated && langCode === "en") {
    playSound('wrong');
    alert("Vui lòng vào Cài đặt để chọn ngôn ngữ dịch (ví dụ: Tiếng Việt, Tây Ban Nha, Pháp, Nhật)!");
    
    // reset toggle
    if (mode === "single") singleState.isTranslated = false;
    else battleState.isTranslated = false;
    isTranslated = false;
  }
  
  let questionText = questionObj.question;
  let optionsList = questionObj.options;
  
  // Check if translation is available
  if (isTranslated && langCode !== "en" && questionObj.translations && questionObj.translations[langCode]) {
    questionText = questionObj.translations[langCode].question;
    optionsList = questionObj.translations[langCode].options;
  }
  
  container.innerHTML = `
    <button class="translate-btn ${isTranslated ? 'active' : ''}" id="${mode}-translate-btn" onclick="toggleTranslation('${mode}')" title="Dịch sang ngôn ngữ đích (ML Kit)">
      <i class="fas fa-language"></i>
    </button>
    <div class="question-text">${questionText}</div>
  `;
  
  optionsContainer.innerHTML = "";
  optionsList.forEach((opt, idx) => {
    const prefix = String.fromCharCode(65 + idx); // A, B, C, D
    const btn = document.createElement("button");
    btn.className = "option-btn";
    btn.innerHTML = `<span class="option-prefix">${prefix}</span> <span class="option-val">${opt}</span>`;
    
    // Check if this option was already chosen and incorrect in double-answer lifeline
    if (mode === "single" && singleState.wrongAnswersSelected.includes(idx)) {
      btn.classList.add("wrong");
      btn.disabled = true;
    }
    
    btn.onclick = () => selectOption(idx, mode);
    optionsContainer.appendChild(btn);
  });
}

function selectOption(selectedIdx, mode) {
  if (mode === "single") {
    const correctIdx = singleState.currentQuestion.answer;
    const optionButtons = document.querySelectorAll("#single-options-container .option-btn");
    
    // Disable all options temporarily to show result
    optionButtons.forEach(btn => btn.disabled = true);
    
    if (selectedIdx === correctIdx) {
      playSound('correct');
      optionButtons[selectedIdx].classList.add("correct");
      
      setTimeout(() => {
        singleState.correctAnswers++;
        singleState.level++;
        singleState.doubleAnswerActive = false; // Reset for next ques
        
        if (singleState.level > 100) {
          showGameOver(true);
        } else {
          loadSingleQuestion();
        }
      }, 1500);
      
    } else {
      playSound('wrong');
      optionButtons[selectedIdx].classList.add("wrong");
      optionButtons[correctIdx].classList.add("correct");
      
      // If Double Answer lifeline is active and we haven't used the second try yet
      if (singleState.doubleAnswerActive && !singleState.doubleAnswerUsedThisQuestion) {
        singleState.doubleAnswerUsedThisQuestion = true;
        singleState.wrongAnswersSelected.push(selectedIdx);
        
        setTimeout(() => {
          // Re-enable remaining options
          alert("Lựa chọn đầu tiên sai. Bạn còn 1 lượt chọn nữa!");
          renderQuestionCard(singleState.currentQuestion, singleState.isTranslated, "single");
        }, 1500);
      } else {
        // Game Over
        setTimeout(() => {
          showGameOver(false);
        }, 1500);
      }
    }
  } else if (mode === "battle") {
    if (battleState.playerAnswered) return;
    playSound('click');
    battleState.playerAnswered = true;
    battleState.playerSelectedIdx = selectedIdx;
    
    // Visually highlight chosen option
    const optionButtons = document.querySelectorAll("#battle-options-container .option-btn");
    optionButtons.forEach((btn, idx) => {
      if (idx === selectedIdx) {
        btn.style.borderColor = "var(--accent-pink)";
        btn.style.background = "rgba(255, 46, 147, 0.1)";
      }
      btn.disabled = true;
    });
    
    // If bot also answered, speed up
    if (battleState.botAnswered) {
      triggerAnswerRevelation();
    }
  }
}

function showGameOver(isWin) {
  const modal = document.getElementById("game-over-overlay");
  const title = document.getElementById("go-title");
  const desc = document.getElementById("go-desc");
  const icon = document.getElementById("go-icon");
  
  modal.classList.remove("hidden");
  
  if (isWin) {
    icon.className = "fas fa-trophy modal-icon";
    icon.style.color = "var(--accent-yellow)";
    title.textContent = "CONGRATULATIONS!";
    desc.textContent = `Bạn đã xuất sắc vượt qua cả 100 câu hỏi và trở thành Triệu Phú!`;
    playSound('win');
  } else {
    icon.className = "fas fa-sad-tear modal-icon";
    icon.style.color = "var(--color-danger)";
    title.textContent = "GAME OVER";
    desc.textContent = `Bạn đã trả lời sai câu hỏi số ${singleState.level}. Tổng số câu đúng: ${singleState.correctAnswers}.`;
  }
  
  // Save High Score
  if (singleState.correctAnswers > gameState.singleHighScore) {
    gameState.singleHighScore = singleState.correctAnswers;
    saveGameData();
  }
}

function closeGameOver() {
  document.getElementById("game-over-overlay").classList.add("hidden");
  showScreen("lobby");
}

// ----------------------------------------------------
// BATTLE MODE LOGIC (1v1 Running Race)
// ----------------------------------------------------
function startBattleMatchmaking() {
  if (gameState.gold < 200) {
    alert("Bạn không đủ 200 Vàng để đặt cọc trận đấu!");
    return;
  }
  
  playSound('click');
  const overlay = document.getElementById("battle-matchmaking-overlay");
  overlay.classList.remove("hidden");
  
  let matchTime = 0;
  const interval = setInterval(() => {
    matchTime++;
    if (matchTime >= 3) { // Simulate 3s match
      clearInterval(interval);
      overlay.classList.add("hidden");
      setupBattleGame();
    }
  }, 1000);
}

function setupBattleGame() {
  // Deduct fee and bet
  gameState.gold -= 200;
  saveGameData();
  updateUIHeader();
  
  battleState = {
    currentQuestion: null,
    questionIndex: 0,
    playerScore: 0,
    botScore: 0,
    timer: 30,
    timerInterval: null,
    playerAnswered: false,
    playerSelectedIdx: null,
    botAnswered: false,
    botSelectedIdx: null,
    showAnswerTimeout: null,
    isTranslated: false,
    botCorrectProbabilities: [0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.5, 0.4]
  };
  
  showScreen("battle");
  updateRunnerPositions();
  loadBattleQuestion();
}

function loadBattleQuestion() {
  clearInterval(battleState.timerInterval);
  clearTimeout(battleState.showAnswerTimeout);
  
  battleState.playerAnswered = false;
  battleState.playerSelectedIdx = null;
  battleState.botAnswered = false;
  battleState.botSelectedIdx = null;
  battleState.timer = 30;
  
  const questionNum = battleState.questionIndex + 1;
  // Chế độ Battle không truyền độ khó (lấy ngẫu nhiên mọi cấp độ từ 1-10)
  const randomLevel = 1 + Math.floor(Math.random() * 10);
  battleState.currentQuestion = getQuestion(randomLevel);
  
  document.getElementById("battle-question-num").textContent = `Question ${questionNum} / 10`;
  document.getElementById("timer-sec").textContent = battleState.timer;
  document.getElementById("timer-fill-bar").style.width = "100%";
  
  renderQuestionCard(battleState.currentQuestion, battleState.isTranslated, "battle");
  
  // Start Timer Countdown
  battleState.timerInterval = setInterval(() => {
    battleState.timer--;
    document.getElementById("timer-sec").textContent = battleState.timer;
    document.getElementById("timer-fill-bar").style.width = `${(battleState.timer / 30) * 100}%`;
    
    if (battleState.timer <= 5 && battleState.timer > 0) {
      playSound('countdown');
    }
    
    if (battleState.timer <= 0) {
      clearInterval(battleState.timerInterval);
      triggerAnswerRevelation();
    }
  }, 1000);
  
  // Bot logic
  simulateBotDecision();
}

function simulateBotDecision() {
  // Bot makes choice between 3s and 15s
  const decisionDelay = 3000 + Math.random() * 12000;
  setTimeout(() => {
    if (gameState.currentScreen !== "battle" || battleState.botAnswered) return;
    
    battleState.botAnswered = true;
    const isBotCorrect = Math.random() < battleState.botCorrectProbabilities[battleState.questionIndex];
    
    if (isBotCorrect) {
      battleState.botSelectedIdx = battleState.currentQuestion.answer;
    } else {
      // Pick wrong answer
      const wrongOptions = [0,1,2,3].filter(idx => idx !== battleState.currentQuestion.answer);
      battleState.botSelectedIdx = wrongOptions[Math.floor(Math.random() * wrongOptions.length)];
    }
    
    // If player also answered, trigger reveal
    if (battleState.playerAnswered) {
      triggerAnswerRevelation();
    }
  }, decisionDelay);
}

function triggerAnswerRevelation() {
  clearInterval(battleState.timerInterval);
  
  // If player hasn't answered, mark wrong
  if (!battleState.playerAnswered) {
    battleState.playerAnswered = true;
    battleState.playerSelectedIdx = -1;
  }
  
  // If bot hasn't answered, pick one
  if (!battleState.botAnswered) {
    battleState.botAnswered = true;
    const isBotCorrect = Math.random() < battleState.botCorrectProbabilities[battleState.questionIndex];
    if (isBotCorrect) {
      battleState.botSelectedIdx = battleState.currentQuestion.answer;
    } else {
      battleState.botSelectedIdx = -1;
    }
  }
  
  // Highlight results on buttons
  const correctIdx = battleState.currentQuestion.answer;
  const optionButtons = document.querySelectorAll("#battle-options-container .option-btn");
  
  optionButtons.forEach((btn, idx) => {
    btn.disabled = true;
    if (idx === correctIdx) {
      btn.classList.add("correct");
    } else {
      if (idx === battleState.playerSelectedIdx) {
        btn.classList.add("wrong");
      }
    }
  });
  
  // Check results and update runner scores
  const playerCorrect = (battleState.playerSelectedIdx === correctIdx);
  const botCorrect = (battleState.botSelectedIdx === correctIdx);
  
  if (playerCorrect) {
    battleState.playerScore++;
    playSound('correct');
  } else {
    if (battleState.playerSelectedIdx !== -1) playSound('wrong');
  }
  
  if (botCorrect) {
    battleState.botScore++;
  }
  
  updateRunnerPositions();
  
  // Show timer text: Show result for 5s
  let countdownReveal = 5;
  document.getElementById("timer-sec").textContent = "Ans";
  document.getElementById("timer-fill-bar").style.width = "0%";
  
  const revealInterval = setInterval(() => {
    countdownReveal--;
    if (countdownReveal <= 0) {
      clearInterval(revealInterval);
      
      // Move to next question or end
      battleState.questionIndex++;
      if (battleState.questionIndex >= 10) {
        endBattleGame();
      } else {
        loadBattleQuestion();
      }
    }
  }, 1000);
}

function updateRunnerPositions() {
  const playerRunner = document.getElementById("player-runner");
  const botRunner = document.getElementById("bot-runner");
  
  // Custom Visuals based on equipped cosmetics
  const pAvatar = playerRunner.querySelector(".runner-avatar");
  
  let hatEmoji = "";
  let shoesEmoji = "";
  let effectEmoji = "";
  
  const hatItem = SHOP_ITEMS.hat.find(h => h.id === gameState.equippedHat);
  const shoesItem = SHOP_ITEMS.shoes.find(s => s.id === gameState.equippedShoes);
  const effectItem = SHOP_ITEMS.effect.find(e => e.id === gameState.equippedEffect);
  
  if (hatItem && hatItem.emoji) hatEmoji = hatItem.emoji;
  if (shoesItem && shoesItem.emoji) shoesEmoji = shoesItem.emoji;
  if (effectItem && effectItem.emoji) effectEmoji = effectItem.emoji;
  
  // Render Custom Runner: Hat on top of player, shoe on foot, trail behind
  pAvatar.textContent = `${hatEmoji}🏃‍♂️${shoesEmoji}${effectEmoji}`;
  
  // Each score gives 10% progress (10 questions max)
  const playerPct = Math.min(100, (battleState.playerScore / 10) * 100);
  const botPct = Math.min(100, (battleState.botScore / 10) * 100);
  
  // Account for runner width, offset by max left limit to keep it within line
  // 0% score is at left: 0px, 100% score is at left: calc(100% - 60px)
  playerRunner.style.left = `calc(${playerPct}% - ${playerPct > 0 ? '60px' : '0px'})`;
  botRunner.style.left = `calc(${botPct}% - ${botPct > 0 ? '60px' : '0px'})`;
  
  document.getElementById("player-score-val").textContent = `${battleState.playerScore}/10`;
  document.getElementById("bot-score-val").textContent = `${battleState.botScore}/10`;
}

function endBattleGame() {
  const modal = document.getElementById("battle-over-overlay");
  const title = document.getElementById("bo-title");
  const desc = document.getElementById("bo-desc");
  const goldReward = document.getElementById("bo-gold-reward");
  const icon = document.getElementById("bo-icon");
  
  modal.classList.remove("hidden");
  
  let goldDiff = 0;
  if (battleState.playerScore > battleState.botScore) {
    // Win! Gets 360 gold (400 - 10% tax)
    goldDiff = 360;
    gameState.gold += goldDiff;
    gameState.accumulatedGold += 360; // Keep track of total earned
    icon.className = "fas fa-trophy modal-icon";
    icon.style.color = "var(--accent-yellow)";
    title.textContent = "VICTORY!";
    desc.textContent = `Bạn đã thắng Bot! Bạn trả lời đúng nhiều hơn (${battleState.playerScore} vs ${battleState.botScore}).`;
    goldReward.textContent = `+360 Gold (Đã trừ 10% thuế)`;
    playSound('win');
  } else if (battleState.playerScore < battleState.botScore) {
    // Loss. Gets 0 back. Lost the 200 bet.
    goldDiff = 0;
    icon.className = "fas fa-sad-tear modal-icon";
    icon.style.color = "var(--color-danger)";
    title.textContent = "DEFEAT";
    desc.textContent = `Bạn đã thua Bot! (${battleState.playerScore} vs ${battleState.botScore}).`;
    goldReward.textContent = `-200 Gold`;
    playSound('wrong');
  } else {
    // Tie. Both get 180 gold back (representing 200 bet - 10% system tax)
    goldDiff = 180;
    gameState.gold += goldDiff;
    gameState.accumulatedGold += 180;
    icon.className = "fas fa-handshake modal-icon";
    icon.style.color = "var(--accent-cyan)";
    title.textContent = "DRAW MATCH";
    desc.textContent = `Hai bên hòa nhau với tỉ số ${battleState.playerScore} - ${battleState.botScore}.`;
    goldReward.textContent = `+180 Gold (Hoàn lại đã trừ 10% thuế)`;
  }
  
  saveGameData();
  updateUIHeader();
}

function closeBattleOver() {
  document.getElementById("battle-over-overlay").classList.add("hidden");
  showScreen("lobby");
}

// ----------------------------------------------------
// SETTINGS LOGIC & GOOGLE ML KIT TRANSLATION MODEL DOWNLOAD
// ----------------------------------------------------
function saveSettings() {
  const nicknameInput = document.getElementById("input-nickname").value.trim();
  const volumeInput = parseInt(document.getElementById("input-volume").value);
  const selectedLang = document.getElementById("select-language").value;
  
  if (nicknameInput) {
    gameState.nickname = nicknameInput;
  }
  gameState.volume = volumeInput;
  
  // Check if target language requires Google ML Kit translation model download (30MB)
  if (selectedLang !== "en" && !gameState.downloadedLanguages.includes(selectedLang)) {
    playSound('click');
    const overlay = document.getElementById("mlkit-download-overlay");
    const fill = document.getElementById("mlkit-progress-fill");
    const percentText = document.getElementById("mlkit-percent-text");
    const descText = document.getElementById("mlkit-download-desc");
    
    overlay.classList.remove("hidden");
    fill.style.width = "0%";
    percentText.textContent = "0%";
    
    let langName = "Tiếng Việt";
    if (selectedLang === "es") langName = "Español (Tây Ban Nha)";
    if (selectedLang === "fr") langName = "Français (Pháp)";
    if (selectedLang === "ja") langName = "日本語 (Nhật Bản)";
    
    descText.textContent = `GOOGLE ML KIT ON-DEVICE TRANSLATION: Đang tải xuống mô hình dịch ngoại tuyến cho ${langName} (30MB)...`;
    
    let progress = 0;
    const interval = setInterval(() => {
      progress += 10;
      fill.style.width = `${progress}%`;
      percentText.textContent = `${progress}%`;
      
      if (progress >= 100) {
        clearInterval(interval);
        setTimeout(() => {
          overlay.classList.add("hidden");
          gameState.downloadedLanguages.push(selectedLang);
          gameState.targetLanguage = selectedLang;
          saveGameData();
          updateUIHeader();
          playSound('correct');
          alert(`Mô hình ngôn ngữ ngoại tuyến ${langName} đã tải thành công về thiết bị! Bây giờ bạn có thể dịch câu hỏi không cần kết nối internet.`);
          showScreen("lobby");
        }, 500);
      }
    }, 200); // 2 seconds total simulation
  } else {
    gameState.targetLanguage = selectedLang;
    saveGameData();
    updateUIHeader();
    playSound('click');
    alert("Settings saved successfully!");
    showScreen("lobby");
  }
}

function handleVolumeChange(val) {
  document.getElementById("volume-val").textContent = val + "%";
  gameState.volume = parseInt(val);
  // Do a quick test click sound
  playSound('click');
}

// ----------------------------------------------------
// SHOP LOGIC (Cosmetics Customization)
// ----------------------------------------------------
function switchShopCategory(category) {
  playSound('click');
  currentShopCategory = category;
  
  // Highlight active tab
  document.getElementById("shop-tab-hat").classList.remove("active");
  document.getElementById("shop-tab-shoes").classList.remove("active");
  document.getElementById("shop-tab-effect").classList.remove("active");
  
  document.getElementById(`shop-tab-${category}`).classList.add("active");
  
  renderShop();
}

function renderShop() {
  const container = document.getElementById("shop-items-list");
  container.innerHTML = "";
  
  const items = SHOP_ITEMS[currentShopCategory];
  
  items.forEach(item => {
    const isOwned = gameState.ownedItems.includes(item.id);
    let isEquipped = false;
    if (currentShopCategory === "hat" && gameState.equippedHat === item.id) isEquipped = true;
    if (currentShopCategory === "shoes" && gameState.equippedShoes === item.id) isEquipped = true;
    if (currentShopCategory === "effect" && gameState.equippedEffect === item.id) isEquipped = true;
    
    let btnHtml = "";
    if (item.price === 0) {
      if (isEquipped) {
        btnHtml = `<button class="reward-btn" style="background:#3a3845; color:var(--text-secondary);" disabled>Equipped</button>`;
      } else {
        btnHtml = `<button class="reward-btn" onclick="equipShopItem('${item.id}', '${currentShopCategory}')">Equip</button>`;
      }
    } else if (isOwned) {
      if (isEquipped) {
        btnHtml = `<button class="reward-btn" style="background:#3a3845; color:var(--text-secondary);" disabled>Equipped</button>`;
      } else {
        btnHtml = `<button class="reward-btn" onclick="equipShopItem('${item.id}', '${currentShopCategory}')">Equip</button>`;
      }
    } else {
      btnHtml = `<button class="reward-btn" onclick="buyShopItem('${item.id}', '${currentShopCategory}', ${item.price})"><i class="fas fa-coins"></i> ${item.price}</button>`;
    }
    
    container.innerHTML += `
      <div class="leaderboard-item">
        <div class="leaderboard-left">
          <span style="font-size: 1.8rem; width: 40px; text-align: center;">${item.emoji || "❌"}</span>
          <div style="display: flex; flex-direction: column;">
            <span class="rank-name">${item.name}</span>
            <span style="font-size: 0.75rem; color: var(--text-secondary);">${isOwned ? 'Đã sở hữu' : 'Chưa sở hữu'}</span>
          </div>
        </div>
        ${btnHtml}
      </div>
    `;
  });
}

function buyShopItem(itemId, category, price) {
  if (gameState.gold < price) {
    playSound('wrong');
    alert("Bạn không đủ Vàng để mua vật phẩm này!");
    return;
  }
  
  playSound('correct');
  gameState.gold -= price;
  gameState.ownedItems.push(itemId);
  saveGameData();
  updateUIHeader();
  renderShop();
  alert(`Đã mua thành công: ${itemId}!`);
}

function equipShopItem(itemId, category) {
  playSound('click');
  if (category === "hat") gameState.equippedHat = itemId;
  if (category === "shoes") gameState.equippedShoes = itemId;
  if (category === "effect") gameState.equippedEffect = itemId;
  
  saveGameData();
  renderShop();
}

// ----------------------------------------------------
// LEADERBOARD LOGIC
// ----------------------------------------------------
function renderLeaderboard(type) {
  const list = document.getElementById("leaderboard-list");
  list.innerHTML = "";
  
  const tabSingle = document.getElementById("rank-tab-single");
  const tabGold = document.getElementById("rank-tab-gold");
  
  if (type === "single") {
    tabSingle.classList.add("active");
    tabGold.classList.remove("active");
    
    // Inject user into ranks if not present
    let combined = [...mockSingleRank];
    if (!combined.some(r => r.nickname === gameState.nickname)) {
      combined.push({ nickname: gameState.nickname, score: gameState.singleHighScore });
    } else {
      // Update score in mock if same name
      const meIdx = combined.findIndex(r => r.nickname === gameState.nickname);
      if (gameState.singleHighScore > combined[meIdx].score) {
        combined[meIdx].score = gameState.singleHighScore;
      }
    }
    
    // Sort
    combined.sort((a, b) => b.score - a.score);
    
    combined.forEach((item, index) => {
      const isMe = item.nickname === gameState.nickname;
      const rankNum = index + 1;
      let rankClass = `rank-number`;
      if (rankNum <= 3) rankClass += ` rank-${rankNum}`;
      
      list.innerHTML += `
        <div class="leaderboard-item ${isMe ? 'me' : ''}">
          <div class="leaderboard-left">
            <span class="${rankClass}">${rankNum}</span>
            <span class="rank-name">${item.nickname} ${isMe ? '(Bạn)' : ''}</span>
          </div>
          <span class="rank-value">${item.score} Correct</span>
        </div>
      `;
    });
    
  } else if (type === "gold") {
    tabSingle.classList.remove("active");
    tabGold.classList.add("active");
    
    let combined = [...mockGoldRank];
    if (!combined.some(r => r.nickname === gameState.nickname)) {
      combined.push({ nickname: gameState.nickname, gold: gameState.accumulatedGold });
    } else {
      const meIdx = combined.findIndex(r => r.nickname === gameState.nickname);
      if (gameState.accumulatedGold > combined[meIdx].gold) {
        combined[meIdx].gold = gameState.accumulatedGold;
      }
    }
    
    combined.sort((a, b) => b.gold - a.gold);
    
    combined.forEach((item, index) => {
      const isMe = item.nickname === gameState.nickname;
      const rankNum = index + 1;
      let rankClass = `rank-number`;
      if (rankNum <= 3) rankClass += ` rank-${rankNum}`;
      
      list.innerHTML += `
        <div class="leaderboard-item ${isMe ? 'me' : ''}">
          <div class="leaderboard-left">
            <span class="${rankClass}">${rankNum}</span>
            <span class="rank-name">${item.nickname} ${isMe ? '(Bạn)' : ''}</span>
          </div>
          <span class="rank-value"><i class="fas fa-coins text-warning"></i> ${item.gold.toLocaleString()}</span>
        </div>
      `;
    });
  }
}

// Simulated Rewarded Ad Flow (CrazyGames/AdMob Simulation)
function showSimulatedAd(onComplete) {
  const modal = document.getElementById("ad-overlay");
  const fill = document.getElementById("ad-progress-fill");
  const text = document.getElementById("ad-sec-text");
  
  modal.classList.remove("hidden");
  fill.style.width = "0%";
  
  let sec = 5;
  text.textContent = sec;
  
  const timer = setInterval(() => {
    sec--;
    text.textContent = sec;
    fill.style.width = `${((5 - sec) / 5) * 100}%`;
    
    if (sec <= 0) {
      clearInterval(timer);
      setTimeout(() => {
        modal.classList.add("hidden");
        if (onComplete) onComplete();
      }, 500);
    }
  }, 1000);
}

// Init Game on load
window.addEventListener("DOMContentLoaded", () => {
  loadGameData();
  showScreen("lobby");
});
