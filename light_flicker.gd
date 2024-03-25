extends SpotLight3D

var original_energy: float = 0.0;
var noise = FastNoiseLite.new();

# Called when the node enters the scene tree for the first time.
func _ready():
	original_energy = light_energy;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var t = Time.get_ticks_msec() / 1000.0 * 50.0;
	var noise_x = fmod(position.x + t, 1000.0);
	var noise_y = fmod(position.y - t, 1200.0);
	var offset = noise.get_noise_2d(noise_x, noise_y);
	light_energy = original_energy + offset * 5.0;
