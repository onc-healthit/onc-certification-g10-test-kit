require_relative '../authorize'

authorize_url = ARGV[0].split('(', 2)[1].split(')').first

authorize(authorize_url, target_patient_id: '85')
