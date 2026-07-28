enum JobStatus {
  pending('Onay Bekliyor'),
  open('Açık'),
  inProgress('Devam Ediyor'),
  completed('Tamamlandı'),
  cancelled('İptal Edildi'),
  rejected('Reddedildi'); // 🚀 Eklendi

  final String label;
  const JobStatus(this.label);
}