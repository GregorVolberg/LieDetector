function [places, characters, weapons, character_items, weapon_items, place_items] = get_crime_stimuli_and_items()

places.png     = {'place1.png', 'place2.png', 'place3.png', 'place4.png'};
places.text    = {'im Park', 'im Einkaufszentrum', 'an der Bushaltestelle', 'im Haus des Opfers'};
places.con     = {'park', 'mall', 'bus_stop', 'house'};
characters.png = {'Blau.png', 'Gelb.png', 'Grün.png', 'Pink.png'};
characters.text= {'blau', 'gelb', 'grün', 'pink'};
characters.con = {'blue', 'yellow', 'green', 'pink'};
weapons.png    = {'Baseball.png', 'Gift.png', 'Kaktus.png', 'weapon4.png'};
weapons.text   = {'ein Baseballschläger', 'Gift', 'ein Kaktus', 'weapon4'};
weapons.con    = {'baseball_bat', 'poison', 'cactus', 'weapon4'};

character_items = ...
{'Der Täter war in # gekleidet.',
'Der Täter hatte etwas in # an.',
'Die Kleidung des Täters war #.',
'Der Mörder trug etwas in #.',
'Hatte der Täter Kleidung in der Farbe # an?',
'War der Täter in # gekleidet?',
'Die Person in # ist schuldig.',
'Die Person mit Kleidung in # war der Täter.'};

weapon_items = ...
{'War die Tatwaffe #?',
'Die Tatwaffe könnte # gewesen sein.',
'Es wurde # benutzt, um das Opfer zu ermorden.',
'Es wurde # benutzt, um dem Opfer Schaden zuzufügen.'};

place_items = ...
{'Waren Sie zur Tatzeit #?',
'Der Täter war zur Tatzeit #.',
'Die Tat hat # stattgefunden.', 
'Haben Sie sich zur Tatzeit # aufgehalten?'};
end