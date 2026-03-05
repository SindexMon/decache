const GALLERY = [
  ["Army of Two- if I were a rich man achievement guide", 50, 41225],
  ["Call of duty 4 glitchs- bomb walk glitch plus tutorial", 50, 41982],
  ["Cod4 glitches- on top of pipline tutorial- old school", 50, 61857],
  ["Cod4 glitches- on top of the map bloc tutorial- old school", 50, 91165],
  ["Cr1TiKaL's 1st Gears of War 2 montage (no bots)", 50, 9478],
  ["Cr1TiKaL's 1st Gears of War 2 sniper montage (no bots)", 50, 25260],
  ["Cr1TiKaL's 1st GoW montage (all ranked)", 50, 555],
  ["Cr1TiKaL's 2nd Gears of War 2 montage", 50, 5401],
  ["Cr1TiKaL's 2nd Gears of War blindfire montage(no snipe match", 50, 1220],
  ["Cr1TiKaL's 3rd Gears of War 2 Montage", 50, 13085],
  ["Cr1TiKaL's 3rd gears of war montage", 50, 975],
  ["Cr1TiKaL's 7th Gears of War sniper montage (All Ranked)", 50, 1739],
  ["Cr1TiKaL's 8th Gears of War sniper montage (All ranked)", 50, 5007],
  ["Cr1TiKaL's 8th Gears of War sniper montage trailer (all ranked)", 50, 669],
  ["Cr1TiKaL's Gears of War 2 Horde montage (comedy tage)", 50, 10477],
  ["Cr1TiKaL's Gears of War Boltok Headshot Montage (Comedy tage)", 50, 1109],
  ["Cr1TiKaL's Gears of War Funtage Episode 1", 50, 910],
  ["Cr1TiKaL's Gears of War Funtage episode 2", 50, 732],
  ["Cr1TiKaL's Gears of War Hammerburst minitage (comedy tage)", 50, 7130],
  ["Gears of war- Cr1TiKaL's 4th sniper montage", 50, 504],
  ["Cr1TiKaL's Modern Warfare 2 Montage #1", 50, 28395],
  ["Cr1TiKaL's first halo 3 sniper montage", 50, 20075],
  ["Cr1TiKaL's first no scope montage", 50, 1390],
  ["Cr1TiKaL's halo 3 montage", 50, 1833],
  ["Cr1TiKaL's second sniper montage", 50, 776],
  ["Cr1TiKaLs multisnipe kill minitage(100% ranked)", 50, 5344],
  ["Gears of War 2 Teamwork Fail", 50, 55593],
  ["Gears of War 2- Destroyed by Debris", 50, 13192],
  ["Gears of War 2- final boss battle and ending cutscene", 50, 16948],
  ["Gears of War Craziest Double Torque Bow kill", 50, 18086],
  ["Gears of War- Are these headshots", 50, 834],
  ["Gears of War- Cr1TiKaL's 5th sniper montage", 50, 3941],
  ["Gears of War- Cr1TiKaL's 6th sniper montage", 50, 655],
  ["Gears of war Jetpack tutorial(NO STANDBYE OR LAG SWITCH)", 50, 8961],
  ["Cr1TiKaL's Modern Warfare 2 'Army of One' Montage", 50, 98328],
  ["Halo 3 - 6 Last Resort glitches", 50, 57015],
  ["Halo 3 glitches- On top of Pelican on Rat's Nest", 50, 50240],
  ["Halo 3 glitches- ghost gun + tutorial", 50, 6300],
  ["Halo 3 glitches- on top of cannon on The Ark + tutorial", 50, 7823],
  ["Halo 3 glitches- outside of Foundry- forge", 50, 90519],
  ["Halo 3 glitches- outside of foundry tutorial- forge", 50, 5859],
  ["Halo 3- 3 Cold Storage glitches + out and under the map", 50, 4830],
  ["Halo 3- 3 amazing kills", 50, 14224],
  ["Halo 3- 8 glitches on foundry", 50, 6798],
  ["Halo 3- Cr1TiKaL's short no scope montage", 50, 1125],
  ["Halo 3- Daark Venoms crazy lone wolfs game", 50, 1323],
  ["Halo 3- amazing triple splatter", 50, 23780],
  ["Halo 3- incredible double splatter aka ninja warthhog", 50, 42963],
  ["Modern Warfare 2 destroying Harriers UAVs Helicopters with pistols", 50, 5722],
  ["Turok- Serpent battle", 50, 1928],
  ["devil may cry 4- boss battle #1", 50, 6378],
  ["devil may cry 4- boss battle #2", 50, 9089],
  ["devil may cry 4- boss battle #3", 50, 6312],
  ["devil may cry 4- boss battle #4", 50, 23896],
  ["devil may cry 4- boss battle #5", 50, 42801],
  ["devil may cry 4- boss battle #6", 50, 7550],
  ["devil may cry 4- boss battle #7", 50, 7195],
  ["devil may cry 4- boss battle #8", 50, 8644],
  ["devil may cry 4- boss battle #9", 50, 7149],
  ["rsv2 glitches- secret room on three kingdoms casino", 50, 17994],
  ["stranglehold final level", 50, 23429]
];

function getImageURL(name) {
  return `images/thumbnails/${name}.jpg`.replace("%", "%25").replace("#", "%23");
}

let currentIndex = 33;

function shoot(isLeft) {
  currentIndex += isLeft ? -1 : 1;

  for (let i = 1; i <= 3; i++) {
    document.getElementById(`thumb${i}`).children[0]["src"] = getImageURL(GALLERY[(currentIndex + i) % GALLERY.length][0]);
  }

  document.getElementById("title").innerHTML = GALLERY[(currentIndex + 2) % GALLERY.length][0];
  document.getElementById("views").children[0].innerHTML = (GALLERY[(currentIndex + 2) % GALLERY.length][2]).toLocaleString();
  document.getElementById("price").children[0].innerHTML = "$" + GALLERY[(currentIndex + 2) % GALLERY.length][1];
}

GALLERY.forEach((data) => {
  const img = new Image();
  img.src = getImageURL(data[0]);
});

document.getElementById("thumb1").onclick = () => shoot(true);
document.getElementById("thumb3").onclick = () => shoot(false);

shoot(true);