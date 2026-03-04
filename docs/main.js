const GALLERY = [
  ["Army of One Montage", 50],
  ["Army of Two- easy 150 kills with pistolsniper guide", 50],
  ["Army of Two- if I were a rich man achievement guide", 50],
  ["Call of duty 4 glitchs- bomb walk glitch plus tutorial", 50],
  ["Cod4 glitches- on top of pipline tutorial- old school", 50],
  ["Cod4 glitches- on top of the map bloc tutorial- old school", 50],
  ["Cr1TiKaL's 1st Gears of War 2 montage (no bots)", 50],
  ["Cr1TiKaL's 1st Gears of War 2 sniper montage (no bots)", 50],
  ["Cr1TiKaL's 1st GoW montage (all ranked)", 50],
  ["Cr1TiKaL's 2nd Gears of War 2 montage", 50],
  ["Cr1TiKaL's 2nd Gears of War blindfire montage(no snipe match", 50],
  ["Cr1TiKaL's 3rd Gears of War 2 Montage", 50],
  ["Cr1TiKaL's 3rd gears of war montage", 50],
  ["Cr1TiKaL's 7th Gears of War sniper montage (All Ranked)", 50],
  ["Cr1TiKaL's 8th Gears of War sniper montage (All ranked)", 50],
  ["Cr1TiKaL's 8th Gears of War sniper montage trailer (all ranked)", 50],
  ["Cr1TiKaL's Gears of War 2 Horde montage (comedy tage)", 50],
  ["Cr1TiKaL's Gears of War Boltok Headshot Montage (Comedy tage)", 50],
  ["Cr1TiKaL's Gears of War Funtage episode 1", 50],
  ["Cr1TiKaL's Gears of War Funtage episode 2", 50],
  ["Cr1TiKaL's Gears of War Hammerburst minitage (comedy tage)", 50],
  ["Cr1TiKaL's Modern Warfare 2 Montage #1", 50],
  ["Cr1TiKaL's first halo 3 sniper montage", 50],
  ["Cr1TiKaL's first no scope montage", 50],
  ["Cr1TiKaL's halo 3 montage", 50],
  ["Cr1TiKaL's second sniper montage", 50],
  ["Cr1TiKaLs multisnipe kill minitage(100% ranked)", 50],
  ["Gears of War 2 Teamwork Fail", 50],
  ["Gears of War 2- Destroyed by Debris", 50],
  ["Gears of War 2- final boss battle and ending cutscene", 50],
  ["Gears of War Craziest Double Torque Bow kill", 50],
  ["Gears of War Funtage episode 3 - YouTube", 50],
  ["Gears of War- Are these headshots", 50],
  ["Gears of War- Cr1TiKaL's 5th sniper montage", 50],
  ["Gears of War- Cr1TiKaL's 6th sniper montage", 50],
  ["Gears of war Jetpack tutorial(NO STANDBYE OR LAG SWITCH)", 50],
  ["Gears of war- Cr1TiKaL's 4th sniper montage", 50],
  ["Halo 3 - 6 Last Resort glitches", 50],
  ["Halo 3 glitches- On top of Pelican on Rat's Nest", 50],
  ["Halo 3 glitches- ghost gun + tutorial", 50],
  ["Halo 3 glitches- on top of cannon on The Ark + tutorial", 50],
  ["Halo 3 glitches- outside of foundry tutorial- forge", 50],
  ["Halo 3 glitches- under avalanche + tutorial", 50],
  ["Halo 3- 3 Cold Storage glitches + out and under the map", 50],
  ["Halo 3- 3 amazing kills", 50],
  ["Halo 3- 8 glitches on foundry", 50],
  ["Halo 3- Cr1TiKaL's short no scope montage", 50],
  ["Halo 3- Daark Venoms crazy lone wolfs game", 50],
  ["Halo 3- amazing triple splatter", 50],
  ["Halo 3- incredible double splatter aka ninja warthhog", 50],
  ["Modern Warfare 2 destroying Harriers UAVs Helicopters with pistols", 50],
  ["Turok- Serpent battle", 50],
  ["devil may cry 4- boss battle #1", 50],
  ["devil may cry 4- boss battle #2", 50],
  ["devil may cry 4- boss battle #3", 50],
  ["devil may cry 4- boss battle #4", 50],
  ["devil may cry 4- boss battle #5", 50],
  ["devil may cry 4- boss battle #6", 50],
  ["devil may cry 4- boss battle #7", 50],
  ["devil may cry 4- boss battle #8", 50],
  ["devil may cry 4- boss battle #9", 50],
  ["rsv2 glitches- secret room on three kingdoms casino", 50],
  ["Halo 3 glitches- outside of Foundry- forge - YouTube", 50],
  ["stranglehold final level", 50]
];

THUMBNAILS.foreach((data) => {
  const img = new Image();
  img.src = `images/thumbnails/${data[0]}.jpg`.replace("#", "%23");
});

let currentIndex = 35;

function shoot(isLeft) {
  currentIndex += isLeft ? -1 : 1;

  for (let i = 1; i <= 3; i++) {
    document.getElementById(`thumb${i}`).children[0]["src"] = `images/thumbnails/${GALLERY[(currentIndex + i) % GALLERY.length][0]}.jpg`.replace("#", "%23");
  }

  document.getElementById("title").innerHTML = GALLERY[(currentIndex + 2) % GALLERY.length][0];
  document.getElementById("price").children[0].innerHTML = "$" + GALLERY[(currentIndex + 2) % GALLERY.length][1];
}

document.getElementById("thumb1").onclick = () => shoot(true);
document.getElementById("thumb3").onclick = () => shoot(false);

shoot(true);