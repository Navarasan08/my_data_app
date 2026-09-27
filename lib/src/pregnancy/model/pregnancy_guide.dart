/// Educational content shown in the Learn tab. General guidance only; the
/// UI shows [disclaimer] alongside it.
class PregnancyWeekGuide {
  final int week;

  /// A familiar size comparison for the baby this week.
  final String babySize;
  final String baby;
  final String mother;
  final String tip;

  const PregnancyWeekGuide({
    required this.week,
    required this.babySize,
    required this.baby,
    required this.mother,
    required this.tip,
  });

  static PregnancyWeekGuide forWeek(int week) {
    final w = week.clamp(1, 42);
    return weeks.lastWhere((g) => g.week <= w, orElse: () => weeks.first);
  }

  static const List<PregnancyWeekGuide> weeks = [
    PregnancyWeekGuide(
      week: 1,
      babySize: 'Not yet',
      baby:
          'Counting starts from the first day of your last period, before conception has happened.',
      mother: 'Your body is preparing for ovulation.',
      tip: 'If you are planning, start folic acid now.',
    ),
    PregnancyWeekGuide(
      week: 4,
      babySize: 'Poppy seed',
      baby: 'The embryo has implanted and the placenta is starting to form.',
      mother:
          'A missed period may be the first sign; a home test can now turn positive.',
      tip: 'Book your first prenatal visit and keep taking folic acid.',
    ),
    PregnancyWeekGuide(
      week: 5,
      babySize: 'Sesame seed',
      baby: 'The neural tube, which becomes the brain and spine, is forming.',
      mother: 'Tiredness and tender breasts are common.',
      tip: 'Avoid alcohol, smoking and unprescribed medicines.',
    ),
    PregnancyWeekGuide(
      week: 6,
      babySize: 'Lentil',
      baby: 'The heart begins to beat and tiny limb buds appear.',
      mother: 'Nausea may start; it often peaks around week 9.',
      tip: 'Small frequent meals and ginger can ease nausea.',
    ),
    PregnancyWeekGuide(
      week: 7,
      babySize: 'Blueberry',
      baby: 'The brain grows quickly and the face starts to take shape.',
      mother: 'You may need to urinate more often.',
      tip: 'Stay hydrated; cut back on caffeine.',
    ),
    PregnancyWeekGuide(
      week: 8,
      babySize: 'Raspberry',
      baby: 'Fingers and toes are forming and the baby begins to move.',
      mother: 'Your uterus is growing, though nothing shows yet.',
      tip: 'Your dating scan usually happens around now.',
    ),
    PregnancyWeekGuide(
      week: 9,
      babySize: 'Cherry',
      baby: 'Major organs are in place; the heartbeat can be seen on a scan.',
      mother: 'Mood swings and fatigue are normal as hormones rise.',
      tip: 'Rest when you can; short walks help energy.',
    ),
    PregnancyWeekGuide(
      week: 10,
      babySize: 'Strawberry',
      baby: 'The embryo is now a fetus; joints can bend.',
      mother: 'Veins may become more visible.',
      tip: 'Ask about first-trimester screening options.',
    ),
    PregnancyWeekGuide(
      week: 11,
      babySize: 'Fig',
      baby: 'Tooth buds and nail beds form; the baby can hiccup.',
      mother: 'Nausea often begins to ease over the next weeks.',
      tip: 'The NT scan window is 11 to 14 weeks.',
    ),
    PregnancyWeekGuide(
      week: 12,
      babySize: 'Lime',
      baby: 'Reflexes develop; fingers open and close.',
      mother: 'Your risk of miscarriage drops sharply after this point.',
      tip: 'Many people share the news around now.',
    ),
    PregnancyWeekGuide(
      week: 13,
      babySize: 'Pea pod',
      baby: 'Vocal cords form and the baby makes urine.',
      mother: 'The first trimester ends; energy usually returns.',
      tip: 'Start iron and calcium if your doctor advises.',
    ),
    PregnancyWeekGuide(
      week: 14,
      babySize: 'Lemon',
      baby: 'The baby can squint and frown; hair follicles appear.',
      mother: 'Appetite often improves.',
      tip: 'Aim for gentle exercise most days.',
    ),
    PregnancyWeekGuide(
      week: 15,
      babySize: 'Apple',
      baby: 'Bones are hardening; the baby senses light.',
      mother: 'A small bump may show.',
      tip: 'Sleeping on your side becomes more comfortable from here.',
    ),
    PregnancyWeekGuide(
      week: 16,
      babySize: 'Avocado',
      baby: 'Eyes can make small movements; the heart pumps a lot of blood.',
      mother:
          'You might feel first flutters, especially in a second pregnancy.',
      tip: 'Time for your second-trimester check-up.',
    ),
    PregnancyWeekGuide(
      week: 17,
      babySize: 'Pear',
      baby: 'The baby practises sucking and swallowing.',
      mother: 'Your centre of gravity shifts; watch your balance.',
      tip: 'Supportive shoes and good posture prevent back pain.',
    ),
    PregnancyWeekGuide(
      week: 18,
      babySize: 'Sweet potato',
      baby: 'The baby hears sounds and its nervous system matures.',
      mother: 'Movements become more noticeable.',
      tip: 'The anomaly scan window is 18 to 22 weeks.',
    ),
    PregnancyWeekGuide(
      week: 19,
      babySize: 'Mango',
      baby: 'A protective coating (vernix) covers the skin.',
      mother: 'Leg cramps and round-ligament aches are common.',
      tip: 'Stretch calves before bed and stay hydrated.',
    ),
    PregnancyWeekGuide(
      week: 20,
      babySize: 'Banana',
      baby: 'Halfway there; the baby swallows more and sleeps in cycles.',
      mother: 'The top of the uterus reaches your navel.',
      tip: 'Talk to the baby; the voice becomes familiar.',
    ),
    PregnancyWeekGuide(
      week: 21,
      babySize: 'Carrot',
      baby: 'Taste buds work; the baby is more active.',
      mother: 'Stretch marks and skin changes can appear.',
      tip: 'Moisturise; wear a supportive bra.',
    ),
    PregnancyWeekGuide(
      week: 22,
      babySize: 'Papaya',
      baby: 'Eyebrows and lips are defined; the grip is developing.',
      mother: 'Mild swelling in feet is common late in the day.',
      tip: 'Put your feet up when you can.',
    ),
    PregnancyWeekGuide(
      week: 23,
      babySize: 'Grapefruit',
      baby: 'Lungs make surfactant to prepare for breathing.',
      mother: 'Braxton Hicks practice contractions may start.',
      tip: 'Learn the difference between practice and real contractions.',
    ),
    PregnancyWeekGuide(
      week: 24,
      babySize: 'Corn',
      baby: 'The face is fully formed; weight gain speeds up.',
      mother: 'The glucose test is usually done between 24 and 28 weeks.',
      tip:
          'Do not skip the OGTT; gestational diabetes is manageable when found early.',
    ),
    PregnancyWeekGuide(
      week: 25,
      babySize: 'Cauliflower',
      baby: 'The baby responds to your voice and touch.',
      mother: 'Heartburn and constipation are common.',
      tip: 'Smaller meals, fibre and fluids help.',
    ),
    PregnancyWeekGuide(
      week: 26,
      babySize: 'Lettuce',
      baby: 'Eyes open; the immune system begins to develop.',
      mother: 'Sleep can get harder; a pillow between the knees helps.',
      tip: 'Ask about the Tdap vaccine for your next visit.',
    ),
    PregnancyWeekGuide(
      week: 27,
      babySize: 'Cabbage',
      baby: 'Brain activity increases; the baby may recognise voices.',
      mother: 'The second trimester ends.',
      tip: 'Start noticing the baby\'s daily movement pattern.',
    ),
    PregnancyWeekGuide(
      week: 28,
      babySize: 'Eggplant',
      baby:
          'The baby can blink and dream; survival outside the womb is likely with care.',
      mother: 'Visits become more frequent from here.',
      tip: 'Begin daily kick counts; report any drop in movement.',
    ),
    PregnancyWeekGuide(
      week: 29,
      babySize: 'Butternut squash',
      baby: 'Muscles and lungs keep maturing; the head grows for the brain.',
      mother: 'Shortness of breath as the uterus pushes up.',
      tip: 'Iron-rich foods: greens, legumes, eggs, lean meat.',
    ),
    PregnancyWeekGuide(
      week: 30,
      babySize: 'Cucumber',
      baby: 'Fat builds under the skin; the baby regulates temperature better.',
      mother: 'Tiredness returns; take it easier.',
      tip: 'Register at the hospital and start a birth plan.',
    ),
    PregnancyWeekGuide(
      week: 31,
      babySize: 'Coconut',
      baby: 'All five senses work; the baby turns its head.',
      mother: 'Colostrum may leak from the breasts.',
      tip: 'Learn about breastfeeding positions now.',
    ),
    PregnancyWeekGuide(
      week: 32,
      babySize: 'Squash',
      baby: 'The baby practises breathing; nails reach the fingertips.',
      mother: 'Pelvic pressure and backache increase.',
      tip: 'A growth scan is often done around now.',
    ),
    PregnancyWeekGuide(
      week: 33,
      babySize: 'Pineapple',
      baby: 'Bones harden except the skull, which stays flexible for birth.',
      mother:
          'Swelling in hands and feet is common; sudden severe swelling is not.',
      tip: 'Know the warning signs of pre-eclampsia.',
    ),
    PregnancyWeekGuide(
      week: 34,
      babySize: 'Cantaloupe',
      baby: 'The baby settles head-down in most pregnancies.',
      mother: 'Sleep in short stretches; naps count.',
      tip: 'Pack the hospital bag this week or next.',
    ),
    PregnancyWeekGuide(
      week: 35,
      babySize: 'Honeydew',
      baby:
          'The kidneys and liver are ready; the baby gains about 200 g a week.',
      mother: 'Frequent urination returns as the baby drops.',
      tip: 'Plan the route and transport to the hospital.',
    ),
    PregnancyWeekGuide(
      week: 36,
      babySize: 'Romaine lettuce',
      baby: 'Considered early term from 37 weeks; lungs are nearly mature.',
      mother: 'Weekly visits begin; the doctor checks the baby\'s position.',
      tip: 'Finalise who is with you at the birth.',
    ),
    PregnancyWeekGuide(
      week: 37,
      babySize: 'Winter melon',
      baby: 'Full term is close; the baby practises grasping.',
      mother: 'Loss of the mucus plug can happen any time now.',
      tip: 'Rest, hydrate and keep your phone charged.',
    ),
    PregnancyWeekGuide(
      week: 38,
      babySize: 'Leek',
      baby: 'Organs are ready for life outside; the baby sheds vernix.',
      mother: 'Practice contractions get stronger.',
      tip: 'Time contractions: regular, stronger and closer means labour.',
    ),
    PregnancyWeekGuide(
      week: 39,
      babySize: 'Pumpkin',
      baby: 'Fully developed and waiting for the signal to arrive.',
      mother: 'Nesting energy is common.',
      tip: 'Go in if your waters break, bleeding starts or movements reduce.',
    ),
    PregnancyWeekGuide(
      week: 40,
      babySize: 'Watermelon',
      baby: 'Due date week; most babies arrive within two weeks either side.',
      mother:
          'Your doctor will discuss monitoring or induction if you go past 41 weeks.',
      tip: 'You have done the hard part. Trust your team.',
    ),
  ];
}

class PregnancyTrimesterGuide {
  final int trimester;
  final String title;
  final String weeks;
  final String summary;
  final List<String> focus;

  const PregnancyTrimesterGuide({
    required this.trimester,
    required this.title,
    required this.weeks,
    required this.summary,
    required this.focus,
  });

  static const List<PregnancyTrimesterGuide> all = [
    PregnancyTrimesterGuide(
      trimester: 1,
      title: 'First trimester',
      weeks: 'Weeks 1–13',
      summary:
          'The baby\'s organs form and your body adapts fast. Tiredness and nausea are common and usually ease by the end of it.',
      focus: [
        'Folic acid daily; avoid alcohol, smoking and raw or undercooked food.',
        'Booking visit, blood tests and dating scan.',
        'NT scan and screening between 11 and 14 weeks.',
        'Rest, small frequent meals and plenty of fluids.',
      ],
    ),
    PregnancyTrimesterGuide(
      trimester: 2,
      title: 'Second trimester',
      weeks: 'Weeks 14–27',
      summary:
          'Often the most comfortable stretch: energy returns, the bump shows and you start feeling movements.',
      focus: [
        'Anomaly scan between 18 and 22 weeks.',
        'Glucose tolerance test between 24 and 28 weeks.',
        'Iron and calcium supplements; iron-rich diet.',
        'Gentle exercise, good posture and side sleeping.',
      ],
    ),
    PregnancyTrimesterGuide(
      trimester: 3,
      title: 'Third trimester',
      weeks: 'Weeks 28–40',
      summary:
          'The baby gains weight quickly and visits become more frequent. Preparation for birth and the newborn takes centre stage.',
      focus: [
        'Daily kick counts from 28 weeks; report reduced movement.',
        'Tdap vaccine, growth scan and weekly visits from 36 weeks.',
        'Hospital registration, birth plan and packed bag by 37 weeks.',
        'Know the signs of labour and when to go in.',
      ],
    ),
  ];
}

/// Symptoms that need same-day medical attention.
const List<String> pregnancyWarningSigns = [
  'Vaginal bleeding or fluid leaking',
  'Severe or persistent abdominal pain',
  'Reduced or no baby movements after 28 weeks',
  'Severe headache, blurred vision or sudden swelling of face and hands',
  'Fever above 38 °C',
  'Painful urination or very dark urine',
  'Regular contractions before 37 weeks',
  'Persistent vomiting and inability to keep fluids down',
];

const List<String> pregnancyNutritionDo = [
  'Plenty of vegetables, fruit, whole grains and pulses',
  'Iron: greens, dates, jaggery, legumes, eggs, lean meat',
  'Calcium: milk, curd, paneer, ragi, sesame',
  'Protein at every meal; 2–3 litres of water a day',
  'Small, frequent meals if nausea or heartburn bothers you',
];

const List<String> pregnancyNutritionAvoid = [
  'Alcohol and smoking',
  'Raw or undercooked meat, eggs and seafood; unpasteurised milk',
  'High-mercury fish (shark, swordfish, king mackerel)',
  'Excess caffeine (keep under about 200 mg a day)',
  'Unwashed produce and street food of uncertain hygiene',
];

const String pregnancyDisclaimer =
    'This guidance is general information, not medical advice. Your doctor\'s '
    'plan comes first: schedules vary by country, hospital and individual '
    'circumstances.';
