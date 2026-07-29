const QUESTION_BANK = [
  // Level 1 (Easy)
  {
    level: 1,
    question: "What is the capital city of France?",
    translations: {
      vi: { question: "Thủ đô của nước Pháp là gì?", options: ["Luân Đôn", "Béc-lin", "Pa-ri", "Rô-ma"] },
      es: { question: "¿Cuál es la capital de Francia?", options: ["Londres", "Berlín", "París", "Roma"] },
      fr: { question: "Quelle est la capitale de la France ?", options: ["Londres", "Berlin", "Paris", "Rome"] },
      ja: { question: "フランスの首都 là gì?", options: ["ロンドン", "ベルリン", "パリ", "ローマ"] }
    },
    options: ["London", "Berlin", "Paris", "Rome"],
    answer: 2 // Paris
  },
  {
    level: 1,
    question: "How many legs does a spider have?",
    translations: {
      vi: { question: "Con nhện có bao nhiêu chân?", options: ["Sáu", "Tám", "Mười", "Mười hai"] },
      es: { question: "¿Cuántas patas tiene una araña?", options: ["Seis", "Ocho", "Diez", "Doce"] },
      fr: { question: "Combien de pattes a une araignée ?", options: ["Six", "Huit", "Dix", "Douze"] },
      ja: { question: "クモの足は何本ですか？", options: ["6本", "8本", "10本", "12本"] }
    },
    options: ["Six", "Eight", "Ten", "Twelve"],
    answer: 1 // Eight
  },
  {
    level: 1,
    question: "Which fruit is associated with Isaac Newton discovering gravity?",
    translations: {
      vi: { question: "Loại quả nào gắn liền với việc Isaac Newton phát hiện ra trọng lực?", options: ["Quả táo", "Quả cam", "Quả chuối", "Quả lê"] },
      es: { question: "¿Qué fruta se asocia con Isaac Newton y la gravedad?", options: ["Manzana", "Naranja", "Plátano", "Pera"] },
      fr: { question: "Quel fruit est associé à Isaac Newton découvrant la gravité ?", options: ["Pomme", "Orange", "Banane", "Poire"] },
      ja: { question: "ニュートンが重力を発見したことに関連する果物は？", options: ["リンゴ", "オレンジ", "バナナ", "洋ナシ"] }
    },
    options: ["Apple", "Orange", "Banana", "Pear"],
    answer: 0 // Apple
  },

  // Level 2
  {
    level: 2,
    question: "Which planet is known as the Red Planet?",
    translations: {
      vi: { question: "Hành tinh nào được gọi là Hành tinh Đỏ?", options: ["Sao Kim", "Sao Hỏa", "Sao Mộc", "Sao Thổ"] },
      es: { question: "¿Qué planeta là Hành tinh Đỏ?", options: ["Venus", "Marte", "Júpiter", "Saturno"] },
      fr: { question: "Quelle planète est connue comme la planète rouge ?", options: ["Vénus", "Mars", "Jupiter", "Saturne"] },
      ja: { question: "赤色惑星として知られる惑星はどれですか？", options: ["金星", "火星", "木星", "土星"] }
    },
    options: ["Venus", "Mars", "Jupiter", "Saturn"],
    answer: 1 // Mars
  },
  {
    level: 2,
    question: "What is the chemical symbol for water?",
    translations: {
      vi: { question: "Kí hiệu hóa học của nước là gì?", options: ["O2", "CO2", "H2O", "NaCl"] },
      es: { question: "¿Cuál es el símbolo químico del agua?", options: ["O2", "CO2", "H2O", "NaCl"] },
      fr: { question: "Quel est le symbole chimique de l'eau ?", options: ["O2", "CO2", "H2O", "NaCl"] },
      ja: { question: "水の化学記号は何ですか？", options: ["O2", "CO2", "H2O", "NaCl"] }
    },
    options: ["O2", "CO2", "H2O", "NaCl"],
    answer: 2 // H2O
  },
  {
    level: 2,
    question: "How many days are there in a leap year?",
    translations: {
      vi: { question: "Năm nhuận có bao nhiêu ngày?", options: ["364", "365", "366", "367"] },
      es: { question: "¿Cuántos días hay en un año bisiesto?", options: ["364", "365", "366", "367"] },
      fr: { question: "Combien de jours y a-t-il dans une année bissextile ?", options: ["364", "365", "366", "367"] },
      ja: { question: "うるう年には何日ありますか？", options: ["364日", "365日", "366日", "367日"] }
    },
    options: ["364", "365", "366", "367"],
    answer: 2 // 366
  },

  // Level 3
  {
    level: 3,
    question: "Who painted the Mona Lisa?",
    translations: {
      vi: { question: "Ai là người đã vẽ bức tranh Mona Lisa?", options: ["Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Claude Monet"] },
      es: { question: "¿Quién pintó la Mona Lisa?", options: ["Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Claude Monet"] },
      fr: { question: "Qui a peint la Joconde ?", options: ["Vincent van Gogh", "Pablo Picasso", "Léonard de Vinci", "Claude Monet"] },
      ja: { question: "モナ・リザを描いたのは誰ですか？", options: ["ゴッホ", "ピカソ", "ダ・ヴィンチ", "モネ"] }
    },
    options: ["Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Claude Monet"],
    answer: 2 // Leonardo da Vinci
  },
  {
    level: 3,
    question: "What is the largest ocean on Earth?",
    translations: {
      vi: { question: "Đại dương nào lớn nhất trên Trái Đất?", options: ["Đại Tây Dương", "Ấn Độ Dương", "Bắc Băng Dương", "Thái Bình Dương"] },
      es: { question: "¿Cuál es el océano más grande de la Tierra?", options: ["Océano Atlántico", "Océano Índico", "Océano Ártico", "Océano Pacífico"] },
      fr: { question: "Quel est le plus grand océan de la Terre ?", options: ["Océan Atlantique", "Océan Indien", "Océan Arctique", "Océan Pacifique"] },
      ja: { question: "地球上で最大の海洋は何ですか？", options: ["大西洋", "インド洋", "北極海", "太平洋"] }
    },
    options: ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean", "Pacific Ocean"],
    answer: 3 // Pacific Ocean
  },

  // Level 4
  {
    level: 4,
    question: "Which element is the most abundant in the Earth's atmosphere?",
    translations: {
      vi: { question: "Nguyên tố nào chiếm tỉ lệ cao nhất trong bầu khí quyển Trái Đất?", options: ["Oxi", "Nitơ", "Cacbon đioxit", "Hydro"] },
      es: { question: "¿Qué elemento es el más abundante en la atmósfera terrestre?", options: ["Oxígeno", "Nitrógeno", "Dióxido de Carbono", "Hidrógeno"] },
      fr: { question: "Quel élément est le plus abondant dans l'atmosphère terrestre ?", options: ["Oxygène", "Azote", "Dioxyde de carbone", "Hydrogène"] },
      ja: { question: "地球の大気中に最も多く存在する元素はどれですか？", options: ["酸素", "窒素", "二酸化炭素", "水素"] }
    },
    options: ["Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen"],
    answer: 1 // Nitrogen
  },
  {
    level: 4,
    question: "Which country is the home of the kangaroo?",
    translations: {
      vi: { question: "Quốc gia nào là quê hương của kangaroo?", options: ["Nam Phi", "Áo", "Úc", "New Zealand"] },
      es: { question: "¿Qué país es el hogar del canguro?", options: ["Sudáfrica", "Austria", "Australia", "Nueva Zelanda"] },
      fr: { question: "Quel pays est la patrie du kangourou ?", options: ["Afrique du Sud", "Autriche", "Australie", "Nouvelle-Zélande"] },
      ja: { question: "カンガルーの故郷である国はどこですか？", options: ["南アフリカ", "オーストリア", "オーストラリア", "ニュージーランド"] }
    },
    options: ["South Africa", "Austria", "Australia", "New Zealand"],
    answer: 2 // Australia
  },

  // Level 5
  {
    level: 5,
    question: "What is the hardest natural substance on Earth?",
    translations: {
      vi: { question: "Chất tự nhiên nào cứng nhất trên Trái Đất?", options: ["Vàng", "Sắt", "Kim cương", "Thạch anh"] },
      es: { question: "¿Cuál es la sustancia natural más dura de la Tierra?", options: ["Oro", "Hierro", "Diamante", "Cuarzo"] },
      fr: { question: "Quelle est la substance naturelle la plus dure sur Terre ?", options: ["Or", "Fer", "Diamant", "Quartz"] },
      ja: { question: "地球上で最も硬い天然物質は何ですか？", options: ["金", "鉄", "ダイヤモンド", "石英"] }
    },
    options: ["Gold", "Iron", "Diamond", "Quartz"],
    answer: 2 // Diamond
  },
  {
    level: 5,
    question: "In what year did the Titanic sink?",
    translations: {
      vi: { question: "Tàu Titanic bị chìm vào năm nào?", options: ["1905", "1912", "1918", "1923"] },
      es: { question: "¿En qué año se hundió el Titanic?", options: ["1905", "1912", "1918", "1923"] },
      fr: { question: "En quelle année le Titanic a-t-il coulé ?", options: ["1905", "1912", "1918", "1923"] },
      ja: { question: "タイタニック号が沈没したのは何年ですか？", options: ["1905年", "1912年", "1918年", "1923年"] }
    },
    options: ["1905", "1912", "1918", "1923"],
    answer: 1 // 1912
  },

  // Level 6
  {
    level: 6,
    question: "Which organ in the human body is responsible for pumping blood?",
    translations: {
      vi: { question: "Cơ quan nào trong cơ thể người có nhiệm vụ bơm máu?", options: ["Brain", "Lungs", "Liver", "Trái tim"] },
      es: { question: "¿Qué órgano del cuerpo humano bombea sangre?", options: ["Cerebro", "Pulmones", "Hígado", "Corazón"] },
      fr: { question: "Quel organe du corps humain est responsable du pompage du sang ?", options: ["Cerveau", "Poumons", "Foie", "Cœur"] },
      ja: { question: "人間の体で血液を送り出す役割を持つ器官はどれですか？", options: ["脳", "肺", "肝臓", "心臓"] }
    },
    options: ["Brain", "Lungs", "Liver", "Heart"],
    answer: 3 // Heart
  },
  {
    level: 6,
    question: "Which country gifted the Statue of Liberty to the United States?",
    translations: {
      vi: { question: "Quốc gia nào đã tặng Tượng Nữ thần Tự do cho Hoa Kỳ?", options: ["Vương quốc Anh", "Pháp", "Đức", "Ý"] },
      es: { question: "¿Qué país regaló la Estatua de la Libertad a los Estados Unidos?", options: ["Reino Unido", "Francia", "Alemania", "Italia"] },
      fr: { question: "Quel pays a offert la Statue de la Liberté aux États-Unis ?", options: ["Royaume-Uni", "France", "Allemagne", "Italie"] },
      ja: { question: "アメリカに自由の女神像を贈った国はどこですか？", options: ["イギリス", "フランス", "ドイツ", "イタリア"] }
    },
    options: ["United Kingdom", "France", "Germany", "Italy"],
    answer: 1 // France
  },

  // Level 7
  {
    level: 7,
    question: "What is the main currency used in Japan?",
    translations: {
      vi: { question: "Đồng tiền chính được sử dụng ở Nhật Bản là gì?", options: ["Nhân dân tệ", "Won", "Yên", "Đô la"] },
      es: { question: "¿Cuál es la moneda principal de Japón?", options: ["Yuan", "Won", "Yen", "Dólar"] },
      fr: { question: "Quelle est la devise principale du Japon ?", options: ["Yuan", "Won", "Yen", "Dollar"] },
      ja: { question: "日本で使われている主な通貨は何ですか？", options: ["人民元", "ウォン", "円", "ドル"] }
    },
    options: ["Yuan", "Won", "Yen", "Dollar"],
    answer: 2 // Yen
  },
  {
    level: 7,
    question: "Who wrote the play 'Romeo and Juliet'?",
    translations: {
      vi: { question: "Ai là tác giả của vở kịch 'Romeo và Juliet'?", options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"] },
      es: { question: "¿Quién escribió la obra 'Romeo y Julieta'?", options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"] },
      fr: { question: "Qui a écrit la pièce 'Roméo et Juliette' ?", options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"] },
      ja: { question: "戯曲『ロミオとジュリエット』を書いたのは誰ですか？", options: ["ディケンズ", "シェイクスピア", "オースティン", "マーク・トウェイン"] }
    },
    options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"],
    answer: 1 // William Shakespeare
  },

  // Level 8
  {
    level: 8,
    question: "How many bones are there in an adult human body?",
    translations: {
      vi: { question: "Có bao nhiêu xương trong cơ thể người trưởng thành?", options: ["186", "206", "216", "256"] },
      es: { question: "¿Cuántos huesos hay en el cuerpo humano adulto?", options: ["186", "206", "216", "256"] },
      fr: { question: "Combien d'os y a-t-il dans un corps humain adulte ?", options: ["186", "206", "216", "256"] },
      ja: { question: "成人の体には何本の骨がありますか？", options: ["186", "206", "216", "256"] }
    },
    options: ["186", "206", "216", "256"],
    answer: 1 // 206
  },
  {
    level: 8,
    question: "Which is the smallest country in the world by area?",
    translations: {
      vi: { question: "Quốc gia nào nhỏ nhất thế giới về diện tích?", options: ["Mô-na-cô", "Man-đi-vơ", "San Ma-ri-nô", "Vatican"] },
      es: { question: "¿Cuál es el país más pequeño del mundo por área?", options: ["Mónaco", "Maldivas", "San Marino", "Vaticano"] },
      fr: { question: "Quel est le plus petit pays du monde en superficie ?", options: ["Monaco", "Maldives", "Saint-Marin", "Vatican"] },
      ja: { question: "世界で最も面積の小さい国はどこですか？", options: ["モナコ", "モルディブ", "サンマリノ", "バチカン市国"] }
    },
    options: ["Monaco", "Maldives", "San Marino", "Vatican City"],
    answer: 3 // Vatican City
  },

  // Level 9
  {
    level: 9,
    question: "What is the speed of light in a vacuum (approximate)?",
    translations: {
      vi: { question: "Tốc độ ánh sáng trong chân không (xấp xỉ) là bao nhiêu?", options: ["300.000 km/s", "150.000 km/s", "450.000 km/s", "600.000 km/s"] },
      es: { question: "¿Cuál es la velocidad de la luz en el vacío?", options: ["300.000 km/s", "150.000 km/s", "450.000 km/s", "600.000 km/s"] },
      fr: { question: "Quelle est la vitesse de la lumière dans le vide (environ) ?", options: ["300 000 km/s", "150 000 km/s", "450 000 km/s", "600 000 km/s"] },
      ja: { question: "真空中の光の速度は（約）どれくらいですか？", options: ["30万 km/s", "15万 km/s", "45万 km/s", "60万 km/s"] }
    },
    options: ["300,000 km/s", "150,000 km/s", "450,000 km/s", "600,000 km/s"],
    answer: 0 // 300,000 km/s
  },
  {
    level: 9,
    question: "Which Nobel Prize did Albert Einstein win in 1921?",
    translations: {
      vi: { question: "Albert Einstein đã giành giải Nobel nào vào năm 1921?", options: ["Hòa bình", "Hóa học", "Văn học", "Vật lý"] },
      es: { question: "¿Qué Premio Nobel ganó Albert Einstein en 1921?", options: ["La Paz", "Química", "Literatura", "Física"] },
      fr: { question: "Quel prix Nobel Albert Einstein a-t-il remporté en 1921 ?", options: ["Paix", "Chimie", "Littérature", "Physique"] },
      ja: { question: "アインシュタインが1921年に受賞したノーベル賞はどれですか？", options: ["平和賞", "化学賞", "文学賞", "物理学賞"] }
    },
    options: ["Peace", "Chemistry", "Literature", "Physics"],
    answer: 3 // Physics
  },

  // Level 10
  {
    level: 10,
    question: "What is the longest river in the world?",
    translations: {
      vi: { question: "Con sông nào dài nhất thế giới?", options: ["Sông Amazon", "Sông Nile", "Sông Trường Giang", "Sông Mississippi"] },
      es: { question: "¿Cuál es el río más largo del mundo?", options: ["Río Amazonas", "Río Nilo", "Río Yangtsé", "Río Misisipi"] },
      fr: { question: "Quel est le plus long fleuve du monde ?", options: ["Amazone", "Nil", "Yangtsé", "Mississippi"] },
      ja: { question: "世界で最も長い川は何ですか？", options: ["アマゾン川", "ナイル川", "長江", "ミシシッピ川"] }
    },
    options: ["Amazon River", "Nile River", "Yangtze River", "Mississippi River"],
    answer: 1 // Nile River
  },
  {
    level: 10,
    question: "Which element has the atomic number 1 on the periodic table?",
    translations: {
      vi: { question: "Nguyên tố nào có số hiệu nguyên tử là 1 trên bảng tuần hoàn?", options: ["Heli", "Hydro", "Lithi", "Oxi"] },
      es: { question: "¿Qué elemento tiene el número atómico 1 en la tabla periódica?", options: ["Helio", "Hidrógeno", "Litio", "Oxígeno"] },
      fr: { question: "Quel élément a le numéro atomique 1 dans le tableau périodique ?", options: ["Hélium", "Hydrogène", "Lithium", "Oxygène"] },
      ja: { question: "周期表で原子番号1の元素はどれですか？", options: ["ヘリウム", "水素", "リチウム", "酸素"] }
    },
    options: ["Helium", "Hydrogen", "Lithium", "Oxygen"],
    answer: 1 // Hydrogen
  }
];

// Helper to get questions by level
function getQuestion(level) {
  // If requested level is out of bank, loop it or choose randomly
  const filtered = QUESTION_BANK.filter(q => q.level === level);
  if (filtered.length > 0) {
    return filtered[Math.floor(Math.random() * filtered.length)];
  }
  // Fallback to random question
  return QUESTION_BANK[Math.floor(Math.random() * QUESTION_BANK.length)];
}
