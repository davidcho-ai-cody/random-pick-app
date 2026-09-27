# Room creates generated database implementations by class name and invokes
# their no-argument constructor through reflection. WorkManager 2.7.0 is
# pulled in by Google Mobile Ads and its Room 2.2.5 consumer rules keep the
# implementation class name, but R8 full mode can still remove the constructor.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
