package affinityoption

type AffinityOption int

const (
	None AffinityOption = iota
	Management
	Measurement
)

func (cao AffinityOption) String() string {
	return []string{"none", "management", "measurement"}[cao]
}

func Parse(opt string) AffinityOption {
	return map[string]AffinityOption{"none": None, "management": Management, "measurement": Measurement}[opt]
}
